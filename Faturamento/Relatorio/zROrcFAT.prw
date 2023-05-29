//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"

//Variaveis utilizadas no fonte inteiro
Static nPadLeft   := 0                                                                     //Alinhamento a Esquerda
Static nPadRight  := 1                                                                     //Alinhamento a Direita
Static nPadCenter := 2                                                                     //Alinhamento Centralizado
Static nPosCod    := 0000                                                                  //Posi��o Inicial da Coluna de C�digo do Produto 
Static nPosDesc   := 0000                                                                  //Posi��o Inicial da Coluna de Descri��o
Static nPosNCM    := 0000                                                                  //Posi��o Inicial da Coluna de NCM
Static nPosUnid   := 0000                                                                  //Posi��o Inicial da Coluna de Unidade de Medida
Static nPosQuan   := 0000                                                                  //Posi��o Inicial da Coluna de Quantidade
Static nPosVUni   := 0000                                                                  //Posi��o Inicial da Coluna de Valor Unitario
Static nPosVTot   := 0000                                                                  //Posi��o Inicial da Coluna de Valor Total
Static nPosBIcm   := 0000                                                                  //Posi��o Inicial da Coluna de Base Calculo ICMS
Static nPosVIcm   := 0000                                                                  //Posi��o Inicial da Coluna de Valor ICMS
Static nPosVIPI   := 0000                                                                  //Posi��o Inicial da Coluna de Valor Ipi
Static nPosAIcm   := 0000                                                                  //Posi��o Inicial da Coluna de Aliquota ICMS
Static nPosAIpi   := 0000                                                                  //Posi��o Inicial da Coluna de Aliquota IPI
Static nPosSTUn   := 0000                                                                  //Posi��o Inicial da Coluna de Valor Unit�rio ST
Static nPosSTVl   := 0000                                                                  //Posi��o Inicial da Coluna de Valor Unit�rio + ST
Static nPosSTBa   := 0000                                                                  //Posi��o Inicial da Coluna de Base do ST
Static nPosSTTo   := 0000                                                                  //Posi��o Inicial da Coluna de Valor Total ST
Static nPosEnt    := 0000                                                                  //Posi��o Inicial da Coluna de Data de Entrega
Static nTamFundo  := 15                                                                    //Altura de fundo dos blocos com t�tulo
Static cEmpEmail  := Alltrim(SuperGetMV("MV_X_EMAIL", .F., "email@empresa.com.br"))        //Par�metro com o e-Mail da empresa
Static cEmpSite   := Alltrim(SuperGetMV("MV_X_HPAGE", .F., "http://www.empresa.com.br"))   //Par�metro com o site da empresa
Static nCorAzul   := RGB(89, 111, 117)                                                     //Cor Azul usada nos T�tulos
Static cNomeFont  := "Arial"                                                               //Nome da Fonte Padr�o
Static oFontDet   := Nil                                                                   //Fonte utilizada na Impress�o dos itens
Static oFontDetN  := Nil                                                                   //Fonte utilizada no cabeçalho dos itens
Static oFontRod   := Nil                                                                   //Fonte utilizada no rodape da P�gina
Static oFontTit   := Nil                                                                   //Fonte utilizada no T�tulo das se��es
Static oFontCab   := Nil                                                                   //Fonte utilizada na Impress�o dos textos dentro das se��es
Static oFontCabN  := Nil                                                                   //Fonte negrita utilizada na Impress�o dos textos dentro das se��es
Static cMaskPad   := "@E 999,999.99"                                                       //M�scara padr�o de valor 
Static cMaskTel   := "@R (99)9999-9999"                                                    //M�scara de telefone / fax
Static cMaskCNPJ  := "@R 99.999.999/9999-99"                                               //M�scara de CNPJ
Static cMaskCEP   := "@R 99999-999"                                                        //M�scara de CEP
Static cMaskCPF   := "@R 999.999.999-99"                                                   //M�scara de CPF
Static cMaskQtd   := PesqPict("SCK", "CK_QTDVEN")                                          //M�scara de quantidade
Static cMaskPrc   := PesqPict("SCK", "CK_VALOR")                                          //M�scara de pre�o
Static cMaskVlr   := PesqPict("SCK", "CK_VALOR")                                           //M�scara de valor
Static cMaskFrete := PesqPict("SCJ", "CJ_FRETE")                                           //M�scara de frete

/*/{Protheus.doc} zROrcFAT
Impress�o Grafica generica de Or�amento de Venda (em pdf)
@type function
@author Atilio
@since 19/06/2016
@version 1.0
	@example
	u_zROrcFAT()
/*/

User Function zROrcFAT()
	Local aArea      := GetArea()
	Local aAreaC5    := SCJ->(GetArea())
	Local aPergs     := {}
	Local aRetorn    := {}
	Local oProcess   := Nil
	//Variaveis usadas nas outras fun��es
	Private cLogoEmp := fLogoEmp()
	Private cOrcDe   := SCJ->CJ_NUM
	Private cOrcAt   := SCJ->CJ_NUM
	Private cLayout  := "1"
	Private cTipoBar := "3"
	Private cZeraPag := "1"
	
	//Adiciona os par�metro para a pergunta
	aAdd(aPergs, {1, "Or�amento De",  cOrcDe, "", ".T.", "SCJ", ".T.", 80, .T.})
	aAdd(aPergs, {1, "Or�amento Ate", cOrcAt, "", ".T.", "SCJ", ".T.", 80, .T.})
	aAdd(aPergs, {2, "Layout",                         Val(cLayout),  {"1=Dados com ST",     "2=Dados com IPI"},                                       100, ".T.", .F.})
	aAdd(aPergs, {2, "C�digo de Barras",               Val(cTipoBar), {"1=N�mero do Or�amento", "2=Filial + N�mero do Or�amento", "3=Sem C�digo de Barras"}, 100, ".T.", .F.})
	aAdd(aPergs, {2, "Zera a P�gina ao trocar Or�amento", Val(cZeraPag), {"1=Sim",           "2=Nao"},                                                 100, ".T.", .F.})
	
	//Se a pergunta for confirmada
	If ParamBox(aPergs, "Informe os par�metro", @aRetorn, , , , , , , , .F., .F.)
		cOrcDe   := aRetorn[1]
		cOrcAt   := aRetorn[2]
		cLayout  := cValToChar(aRetorn[3])
		cTipoBar := cValToChar(aRetorn[4])
		cZeraPag := cValToChar(aRetorn[5])
		
		//Funcao que muda alinhamento e fontes
		fMudaLayout()
		
		//Chama o processamento do relat�rio
		oProcess := MsNewProcess():New({|| fMontaRel(@oProcess) }, "Impress�o Or�amentos de Venda", "Processando", .F.)
		oProcess:Activate()
	EndIf
	
	RestArea(aAreaC5)
	RestArea(aArea)
Return

/*---------------------------------------------------------------------*
 | Func:  fMontaRel                                                    |
 | Desc:  Funcao principal que monta o relat�rio                       |
 *---------------------------------------------------------------------*/

Static Function fMontaRel(oProc)
	//Variaveis usada no controle das r�guas
	Local nTotIte       := 0
	Local nItAtu        := 0
	Local nTotPed       := 0
	Local nPedAtu       := 0
	//Consultas SQL
	Local cQryPed       := ""
	Local cQryIte       := ""
	//Valores de Impostos
	Local nBasICM       := 0
	Local nValICM       := 0
	Local nValIPI       := 0
	Local nAlqICM       := 0
	Local nAlqIPI       := 0
	Local nValSol       := 0
	Local nBasSol       := 0
	Local nPrcUniSol    := 0
	Local nTotSol       := 0
	//Variaveis do relat�rio
	Local cNomeRel      := "Orcamento_venda_"+FunName()+"_"+RetCodUsr()+"_"+dToS(Date())+"_"+StrTran(Time(), ":", "")
	Local aSX3Box       := RetSX3Box(GetSX3Cache("CK_XPRZENT", "X3_CBOX"),,,1)
	Local nValSV        := 0
	Private oPrintPvt
	Private cHoraEx     := Time()
	Private nPagAtu     := 1
	//Linhas e colunas
	Private nLinAtu     := 0
	Private nLinFin     := 580
	Private nColIni     := 010
	Private nColFin     := 820
	Private nColMeio    := (nColFin-nColIni)/2
	//Totalizadores
	Private nTotFrete   := 0
	Private nValorTot   := 0
	Private nTotalST    := 0
	Private nTotVal     := 0
	Private nTotIPI     := 0
	Private nDesconto   := 0
	
	DbSelectArea("SB1")
	SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
	SB1->(DbGoTop())
	DbSelectArea("SCJ")
	
	//Criando o objeto de Impressao
	oPrintPvt := FWMSPrinter():New(cNomeRel, IMP_PDF, .F., /*cStartPath*/, .T., , @oPrintPvt, , , , , .T.)
	oPrintPvt:cPathPDF := GetTempPath()
	oPrintPvt:SetResolution(72)
	oPrintPvt:SetLandscape()
	oPrintPvt:SetPaperSize(DMPAPER_A4)
	oPrintPvt:SetMargin(10, 10, 10, 10)
	
	//Selecionando os Or�amentos
	cQryPed := " SELECT "                                        + CRLF
	cQryPed += "    CJ_FILIAL, "                                 + CRLF
	cQryPed += "    CJ_NUM, "                                    + CRLF
	cQryPed += "    CJ_EMISSAO, "                                + CRLF
	cQryPed += "    CJ_CLIENTE, "                                + CRLF
	cQryPed += "    CJ_LOJA, "                                   + CRLF
	cQryPed += "    CJ_XMSGI, "                                  + CRLF
	cQryPed += "    ISNULL(A1_NOME, '') AS A1_NOME, "       	 + CRLF
	cQryPed += "    ISNULL(A1_NREDUZ, '') AS A1_NREDUZ, "      	 + CRLF
	cQryPed += "    ISNULL(A1_PESSOA, '') AS A1_PESSOA, "        + CRLF
	cQryPed += "    ISNULL(A1_CGC, '') AS A1_CGC, "              + CRLF
	cQryPed += "    ISNULL(A1_END, '') AS A1_END, "              + CRLF
	cQryPed += "    ISNULL(A1_BAIRRO, '') AS A1_BAIRRO, "        + CRLF
	cQryPed += "    ISNULL(A1_MUN, '') AS A1_MUN, "              + CRLF
	cQryPed += "    ISNULL(A1_EST, '') AS A1_EST, "              + CRLF
	cQryPed += "    ISNULL(A1_DDD, '') AS A1_DDD, "       		 + CRLF
	cQryPed += "    ISNULL(A1_TEL, '') AS A1_TEL, "       		 + CRLF
	cQryPed += "    ISNULL(A1_EMAIL, '') AS A1_EMAIL, "       	 + CRLF
	cQryPed += "    CJ_CONDPAG, "                                + CRLF
	cQryPed += "    ISNULL(E4_DESCRI, '') AS E4_DESCRI, "        + CRLF
	cQryPed += "    CJ_TPFRETE, "                                + CRLF
	cQryPed += "    CJ_FRETE, "                                  + CRLF
	cQryPed += "    SCJ.R_E_C_N_O_ AS CJREC "                    + CRLF
	cQryPed += " FROM "                                          + CRLF
	cQryPed += "    "+RetSQLName("SCJ")+" SCJ "                  + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SA1")+" SA1 ON ( "   + CRLF
	cQryPed += "        A1_FILIAL   = '"+FWxFilial("SA1")+"' "   + CRLF
	cQryPed += "        AND A1_COD  = SCJ.CJ_CLIENTE "           + CRLF
	cQryPed += "        AND A1_LOJA = SCJ.CJ_LOJA "           + CRLF
	cQryPed += "        AND SA1.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SE4")+" SE4 ON ( "   + CRLF
	cQryPed += "        E4_FILIAL     = '"+FWxFilial("SE4")+"' " + CRLF
	cQryPed += "        AND E4_CODIGO = SCJ.CJ_CONDPAG "         + CRLF
	cQryPed += "        AND SE4.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += " WHERE "                                         + CRLF
	cQryPed += "    CJ_FILIAL   = '"+FWxFilial("SCJ")+"' "       + CRLF
	cQryPed += "    AND CJ_NUM >= '"+cOrcDe+"' "                 + CRLF
	cQryPed += "    AND CJ_NUM <= '"+cOrcAt+"' "                 + CRLF
	cQryPed += "    AND SCJ.D_E_L_E_T_ = ' ' "                   + CRLF
	TCQuery cQryPed New Alias "QRY_PED"
	TCSetField("QRY_PED", "CJ_EMISSAO", "D")
	Count To nTotPed
	oProc:SetRegua1(nTotPed)
	
	//Somente se houver Or�amentos
	If nTotPed != 0
	
		//Enquanto houver Or�amentos
		QRY_PED->(DbGoTop())
		While ! QRY_PED->(EoF())
			If cZeraPag == "1"
				nPagAtu := 1
			EndIf
			nPedAtu++
			oProc:IncRegua1("Processando o Or�amento "+cValToChar(nPedAtu)+" de "+cValToChar(nTotPed)+"...")
			oProc:SetRegua2(1)
			oProc:IncRegua2("...")
			
			//Imprime o cabecalho
			fImpCab()
			
			//Inicializa os calculos de impostos
			nItAtu    := 0
			nTotIte   := 0
			nTotalST  := 0
			nTotIPI   := 0
			nDesconto := 0
			SCJ->(DbGoTo(QRY_PED->CJREC))
			MaFisIni(SCJ->CJ_CLIENTE,;                   // 01 - C�digo Cliente/Fornecedor
				SCJ->CJ_LOJA,;                           // 02 - Loja do Cliente/Fornecedor
				Iif(SCJ->CJ_TIPO $ "D;B", "F", "C"),;    // 03 - C:Cliente , F:Fornecedor
				SCJ->CJ_TIPO,;                           // 04 - Tipo da NF
				SCJ->CJ_TIPOCLI,;                        // 05 - Tipo do Cliente/Fornecedor
				MaFisRelImp("MT100", {"SF2", "SD2"}),;   // 06 - Relacao de Impostos que suportados no arquivo
				,;                                       // 07 - Tipo de complemento
				,;                                       // 08 - Permite Incluir Impostos no Rodape .T./.F.
				"SB1",;                                  // 09 - Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
				"MATA461")                               // 10 - Nome da rotina que esta utilizando a funcao
			
			//Seleciona agora os itens do Or�amento
			cQryIte := " SELECT "                                      + CRLF
			cQryIte += "    CK_PRODUTO, "                              + CRLF
			cQryIte += "    ISNULL(B1_DESC, '') AS B1_DESC, "          + CRLF
			cQryIte += "    ISNULL(B1_POSIPI, '') AS B1_POSIPI, "      + CRLF
			cQryIte += "    ISNULL(B1_TIPO, '') AS B1_TIPO, "          + CRLF
			cQryIte += "    CK_UM, "                                   + CRLF
			cQryIte += "    CK_ENTREG, "                               + CRLF
			cQryIte += "    CK_TES, "                                  + CRLF
			cQryIte += "    CK_QTDVEN, "                               + CRLF
			cQryIte += "    CK_PRCVEN, "                               + CRLF
			cQryIte += "    CK_VALDESC, "                              + CRLF
			cQryIte += "    CK_VALOR, "                                + CRLF
			cQryIte += "    CK_XPRZENT "                               + CRLF
			cQryIte += " FROM "                                        + CRLF
			cQryIte += "    "+RetSQLName("SCK")+" SCK "                + CRLF
			cQryIte += "    LEFT JOIN "+RetSQLName("SB1")+" SB1 ON ( " + CRLF
			cQryIte += "        B1_FILIAL = '"+FWxFilial("SB1")+"' "   + CRLF
			cQryIte += "        AND B1_COD = SCK.CK_PRODUTO "          + CRLF
			cQryIte += "        AND SB1.D_E_L_E_T_ = ' ' "             + CRLF
			cQryIte += "    ) "                                        + CRLF
			cQryIte += " WHERE "                                       + CRLF
			cQryIte += "    CK_FILIAL = '"+FWxFilial("SCK")+"' "       + CRLF
			cQryIte += "    AND CK_NUM = '"+QRY_PED->CJ_NUM+"' "       + CRLF
			cQryIte += "    AND SCK.D_E_L_E_T_ = ' ' "                 + CRLF
			cQryIte += " ORDER BY "                                    + CRLF
			cQryIte += "    CK_ITEM "                                  + CRLF
			TCQuery cQryIte New Alias "QRY_ITE"
			TCSetField("QRY_ITE", "CK_ENTREG", "D")
			Count To nTotIte
			nValorTot := 0
			oProc:SetRegua2(nTotIte)
			
			//Enquanto houver itens
			QRY_ITE->(DbGoTop())
			While ! QRY_ITE->(EoF())
				nItAtu++
				oProc:IncRegua2("Calculando impostos - item "+cValToChar(nItAtu)+" de "+cValToChar(nTotIte)+"...")
				
				//Pega os tratamentos de impostos
				SB1->(DbSeek(FWxFilial("SB1")+QRY_ITE->CK_PRODUTO))
				MaFisAdd(QRY_ITE->CK_PRODUTO,;    // 01 - C�digo do Produto                    ( Obrigatorio )
					QRY_ITE->CK_TES,;             // 02 - C�digo do TES                        ( Opcional )
					QRY_ITE->CK_QTDVEN,;          // 03 - Quantidade                           ( Obrigatorio )
					QRY_ITE->CK_PRCVEN,;          // 04 - Preco Unitario                       ( Obrigatorio )
					0,;         				  // 05 - Desconto
					0,;                           // 08 - RecNo da NF Original no arq SD1/SD2
					0,;                           // 09 - Valor do Frete do Item               ( Opcional )
					0,;                           // 10 - Valor da Despesa do item             ( Opcional )
					0,;                           // 11 - Valor do Seguro do item              ( Opcional )
					0,;                           // 12 - Valor do Frete Autonomo              ( Opcional )
					QRY_ITE->CK_VALOR,;           // 13 - Valor da Mercadoria                  ( Obrigatorio )
					0,;                           // 14 - Valor da Embalagem                   ( Opcional )
					SB1->(RecNo()),;              // 15 - RecNo do SB1
					0)                            // 16 - RecNo do SF4
				
				nQtdPeso := QRY_ITE->CK_QTDVEN*SB1->B1_PESO
				MaFisLoad("IT_VALMERC", QRY_ITE->CK_VALOR, nItAtu)				
				MaFisAlt("IT_PESO", nQtdPeso, nItAtu)
				
				QRY_ITE->(DbSkip())
			EndDo
			
			//Altera dados da Nota
			MaFisAlt("NF_FRETE", SCJ->CJ_FRETE)
			MaFisAlt("NF_SEGURO", SCJ->CJ_SEGURO)
			MaFisAlt("NF_AUTONOMO", SCJ->CJ_FRETAUT)
			If SCJ->CJ_DESCONT > 0
				MaFisAlt("NF_DESCONTO", Min(MaFisRet(, "NF_VALMERC")-0.01, SCJ->CJ_DESCONT+MaFisRet(, "NF_DESCONTO")) )
			EndIf
			If SCJ->CJ_PDESCAB > 0
				MaFisAlt("NF_DESCONTO", A410Arred(MaFisRet(, "NF_VALMERC")*SCJ->CJ_PDESCAB/100, "CK_VALOR") + MaFisRet(, "NF_DESCONTO"))
			EndIf
			
			//Enquanto houver itens
			oProc:IncRegua2("...")
			oProc:SetRegua2(nTotIte)
			nItAtu := 0
			QRY_ITE->(DbGoTop())
			While ! QRY_ITE->(EoF())
				nItAtu++
				oProc:IncRegua2("Imprimindo item "+cValToChar(nItAtu)+" de "+cValToChar(nTotIte)+"...")
				
				//Pega os tratamentos de impostos
				SB1->(DbSeek(FWxFilial("SB1")+QRY_ITE->CK_PRODUTO))
				
				//Pega os valores
				nBasICM    := MaFisRet(nItAtu, "IT_BASEICM")
				nValICM    := MaFisRet(nItAtu, "IT_VALICM")
				nValIPI    := MaFisRet(nItAtu, "IT_VALIPI")
				nAlqICM    := MaFisRet(nItAtu, "IT_ALIQICM")
				nAlqIPI    := MaFisRet(nItAtu, "IT_ALIQIPI")
				nValSol    := (MaFisRet(nItAtu,"IT_VALSOL") / QRY_ITE->CK_QTDVEN) 
				nBasSol    := MaFisRet(nItAtu, "IT_BASESOL")
				nPrcUniSol := QRY_ITE->CK_PRCVEN + nValSol
				nTotSol    := nPrcUniSol * QRY_ITE->CK_QTDVEN
				nTotalST   += MaFisRet(nItAtu, "IT_VALSOL")
				nTotIPI    += nValIPI
				nDesconto  += QRY_ITE->CK_VALDESC
				
				//Imprime os dados
				If cLayout == "1"
					oPrintPvt:SayAlign(nLinAtu, nPosCod, QRY_ITE->CK_PRODUTO,                                oFontDet, 200, 35, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosDesc, QRY_ITE->B1_DESC,                                  oFontDet, 200, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosUnid, QRY_ITE->CK_UM,                                    oFontDet, 030, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosNCM , QRY_ITE->B1_POSIPI,                                oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosQuan, Alltrim(Transform(QRY_ITE->CK_QTDVEN, cMaskQtd)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVUni, Alltrim(Transform(QRY_ITE->CK_PRCVEN, cMaskPrc)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVTot, Alltrim(Transform(QRY_ITE->CK_VALOR, cMaskVlr)),   oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosSTVl, Alltrim(Transform(nPrcUniSol, cMaskPrc)),          oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosSTTo, Alltrim(Transform(nTotSol, cMaskVlr)),             oFontDet, 050, 07, , nPadLeft,) 
					oPrintPvt:SayAlign(nLinAtu, nPosAIcm, Alltrim(Transform(nAlqICM, cMaskPad)),             oFontDet, 050, 07, , nPadLeft,)
					If !Empty(QRY_ITE->CK_XPRZENT)
					oPrintPvt:SayAlign(nLinAtu, nPosEnt , Alltrim(aSX3Box[Val(QRY_ITE->CK_XPRZENT),3]),      oFontDet, 050, 07, , nPadLeft,)
					EndIf 
				Else
					oPrintPvt:SayAlign(nLinAtu, nPosCod , QRY_ITE->CK_PRODUTO,                               oFontDet, 200, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosDesc, QRY_ITE->B1_DESC,                                  oFontDet, 200, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosUnid, QRY_ITE->CK_UM,                                    oFontDet, 030, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosNCM , QRY_ITE->B1_POSIPI,                                oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosQuan, Alltrim(Transform(QRY_ITE->CK_QTDVEN, cMaskQtd)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVUni, Alltrim(Transform(QRY_ITE->CK_PRCVEN, cMaskPrc)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVTot, Alltrim(Transform(QRY_ITE->CK_VALOR, cMaskVlr)),   oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosAIcm, Alltrim(Transform(nAlqICM, cMaskPad)),             oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosAIpi, Alltrim(Transform(nAlqIPI, cMaskPad)),             oFontDet, 050, 07, , nPadLeft,)
					If !Empty(QRY_ITE->CK_XPRZENT)
					oPrintPvt:SayAlign(nLinAtu, nPosEnt , Alltrim(aSX3Box[Val(QRY_ITE->CK_XPRZENT),3]),      oFontDet, 050, 07, , nPadLeft,)
					EndIf
				EndIf

				nLinAtu += 10
				
				//Se por acaso atingiu o limite da pagina, finaliza, e come�a uma nova pagina
				If nLinAtu >= nLinFin
					fImpRod()
					fImpCab()
				EndIf
				
				nValorTot += QRY_ITE->CK_VALOR
				If QRY_ITE->B1_TIPO == "SV"
					nValSV += QRY_ITE->CK_VALOR
				EndIF
				QRY_ITE->(DbSkip())
			EndDo
			nTotFrete := MaFisRet(, "NF_FRETE")
			nTotVal := MaFisRet(, "NF_TOTAL")
			nTotVal := (nTotVal - nValSV)
			QRY_ITE->(DbCloseArea())
			MaFisEnd()
			
			//Imprime o Total do Or�amento
			fImpTot()
			
			//Se tiver observa��es
			If SCJ->(FieldPos("CJ_XMSGI") > 0)
				If !Empty(SCJ->CJ_XMSGI)
					fMsgObs()
				EndIf 
			EndIf
			
			//Imprime o rodape
			fImpRod()
			
			QRY_PED->(DbSkip())
		EndDo
		
		//Gera o pdf para visualizacao
		oPrintPvt:Preview()
	
	Else
		MsgStop("N�o h� Or�amentos!", "Aten��o")
	EndIf
	QRY_PED->(DbCloseArea())
Return

/*---------------------------------------------------------------------*
 | Func:  fImpCab                                                      |
 | Desc:  Funcao que imprime o cabecalho                               |
 *---------------------------------------------------------------------*/

Static Function fImpCab()
	//Local cTexto      := ""
	Local nLinCab     := 025
	Local nLinCabOrig := nLinCab
	Local cCodBar     := ""
	//Local nColMeiPed  := nColMeio+8+((nColMeio-nColIni)/2)
	Local lCNPJ       := (QRY_PED->A1_PESSOA != "F")
	Local cCliAux     := QRY_PED->CJ_CLIENTE+" "+QRY_PED->CJ_LOJA+" - "+QRY_PED->A1_NOME
	Local cCGC        := ""
	Local cFretePed   := ""
	//Dados da empresa
	Local cEmpresa    := Iif(Empty(SM0->M0_NOMECOM), Alltrim(SM0->M0_NOME), Alltrim(SM0->M0_NOMECOM))
	Local cEmpTel     := Alltrim(Transform(SubStr(SM0->M0_TEL, 1, Len(SM0->M0_TEL)), cMaskTel))
	Local cEmpFax     := Alltrim(Transform(SubStr(SM0->M0_FAX, 1, Len(SM0->M0_FAX)), cMaskTel))
	Local cEmpCidade  := AllTrim(SM0->M0_CIDENT)+" / "+SM0->M0_ESTENT
	Local cEmpCnpj    := Alltrim(Transform(SM0->M0_CGC, cMaskCNPJ))
	Local cEmpCep     := Alltrim(Transform(SM0->M0_CEPENT, cMaskCEP))
	
	//Iniciando P�gina
	oPrintPvt:StartPage()
	
	//Dados da Empresa
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + 150, nColMeio-3)
	oPrintPvt:Line(nLinCab+nTamFundo, nColIni, nLinCab+nTamFundo, nColMeio-3)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColIni+5, "Emitente:",                                      oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayBitmap(nLinCab+3, nColIni+5, cLogoEmp, 054, 054)
	oPrintPvt:SayAlign(nLinCab,    nColIni+65, "Empresa:",                                      oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColIni+110, cEmpresa,                                       oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "CNPJ:",                                          oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpCnpj,                                        oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Cidade:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpCidade,                                      oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "CEP:",                                           oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpCep,                                         oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Telefone:",                                      oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpTel,                                         oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Telefone:",                                      oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpFax,                                         oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "e-Mail:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpEmail,                                       oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Site:",                                     		oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpSite,                                        oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	
	//Dados do Or�amentox
	nLinCab := nLinCabOrig
	oPrintPvt:Box(nLinCab, nColMeio+3, nLinCab + 150, nColFin)
	oPrintPvt:Line(nLinCab+nTamFundo, nColMeio+3, nLinCab+nTamFundo, nColFin)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColMeio+8,  "Or�amento:",                                   oFontTit,  080, nTamFundo, nCorAzul, nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Num.Or�amento:",                               oFontCabN, 100, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+75, QRY_PED->CJ_NUM,                                oFontCab,  100, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Dt.Emissao:",                                  oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+58, dToC(QRY_PED->CJ_EMISSAO),                      oFontCab,  100, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Cliente:",                                     oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+38, cCliAux,                                        oFontCab, 300, 07, , nPadLeft,  )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Nome Fantasia:",                               oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+68, QRY_PED->A1_NREDUZ,  	                        oFontCab, 300, 07, , nPadLeft,  )
	nLinCab += 10
	cCGC := QRY_PED->A1_CGC
	If lCNPJ
		cCGC := Iif(!Empty(cCGC), Alltrim(Transform(cCGC, cMaskCNPJ)), "-")
		oPrintPvt:SayAlign(nLinCab, nColMeio+8, "CNPJ:",                                        oFontCabN, 060, 07, , nPadLeft, )
	Else
		cCGC := Iif(!Empty(cCGC), Alltrim(Transform(cCGC, cMaskCPF)), "-")
		oPrintPvt:SayAlign(nLinCab, nColMeio+8, "CPF:",                                         oFontCabN, 060, 07, , nPadLeft, )
	EndIf
	oPrintPvt:SayAlign(nLinCab, nColMeio+32, cCGC,                                              oFontCab,  300, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Telefone:",	                                    oFontCabN, 035, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+045,"("+Alltrim(QRY_PED->A1_DDD)+") "+;
											 Alltrim(QRY_PED->A1_TEL),							oFontCab,  250, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "E-mail:",		                                    oFontCabN, 030, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+038, QRY_PED->A1_EMAIL,		 						oFontCab,  250, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Endereco:",	                                    oFontCabN, 040, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+048, QRY_PED->A1_END,			 						oFontCab,  250, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Bairro, Cidade - UF:",                             oFontCabN, 090, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+85, Alltrim(QRY_PED->A1_BAIRRO)+;
											  ","+Alltrim(QRY_PED->A1_MUN)+;
											  " - "+QRY_PED->A1_EST, 							oFontCab,  250, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Frete:",                                           oFontCabN, 060, 07, , nPadLeft, )
	If QRY_PED->CJ_TPFRETE == "C"
		cFretePed := "CIF"
	ElseIf QRY_PED->CJ_TPFRETE == "F"
		cFretePed := "FOB"
	ElseIf QRY_PED->CJ_TPFRETE == "T"
		cFretePed := "Terceiros"
	Else
		cFretePed := "Sem Frete"
	EndIf
	cFretePed += " - "+Alltrim(Transform(QRY_PED->CJ_FRETE, cMaskFrete))
	oPrintPvt:SayAlign(nLinCab, nColMeio+32, cFretePed,                                         oFontCab,  060, 07, , nPadLeft, )
	nLinCab += 13

	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Condi��o de Pagamento:  ",                         oFontCabN, 150, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+105, QRY_PED->E4_DESCRI,                               oFontCab,  250, 07, , nPadLeft, )

	//C�digo de barras
	nLinCab := nLinCabOrig
	If cTipoBar $ "1;2"
		If cTipoBar == "1"
			cCodBar := QRY_PED->CJ_NUM
		ElseIf cTipoBar == "2"
			cCodBar := QRY_PED->CJ_FILIAL+QRY_PED->CJ_NUM
		EndIf
		oPrintPvt:Code128C(nLinCab+90+nTamFundo, nColFin-60, cCodBar, 28)
		oPrintPvt:SayAlign(nLinCab+92+nTamFundo, nColFin-60, cCodBar, oFontRod, 080, 07, , nPadLeft, )
	EndIf

	//Ti�tulo
	nLinCab := nLinCabOrig + 155
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + nTamFundo, nColFin)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColIni, "Itens do Or�amento de Venda:", oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	
	//Linha Separatorio
	nLinCab += 5
	
	//Cabecalho com descricao das colunas
	nLinCab += 7
	If cLayout == "1"
		oPrintPvt:SayAlign(nLinCab,   nPosCod,  "Cod.Prod.",        oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosDesc, "Descricao",        oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosUnid, "Uni.Med.",         oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosNCM , "NCM"      ,        oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosQuan, "Quant.",           oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosVUni, "Prc. Unit.",		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVUni, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosVTot, "Vlr. Total", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVTot, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosSTVl, "Prc. Unit.",       oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosSTVl, "+ Imposto",       oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosSTTo, "Vl.Total",         oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosSTTo, "+ Imposto",       oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosAIcm, "A.ICMS",           oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosEnt , "Prz. Dias",        oFontDetN, 050, 07, , nPadLeft,)
	 Else
		oPrintPvt:SayAlign(nLinCab, nPosCod,  "Cod.Prod.",          oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosDesc, "Descricao",          oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosUnid, "Uni.Med.",           oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosNCM , "NCM"      ,          oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosQuan, "Quant.",             oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,    nPosVUni, "Prc. Unit.",		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVUni, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,    nPosVTot, "Vlr. Total", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVTot, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosAIcm, "A.ICMS",             oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosAIpi, "A.IPI",              oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosEnt , "Prz. Dias",          oFontDetN, 050, 07, , nPadLeft,)
	EndIf
	
	//Atualizando a linha inicial do relat�rio
	nLinAtu := nLinCab + 20
Return

/*---------------------------------------------------------------------*
 | Func:  fImpRod                                                      |
 | Desc:  Funcao que imprime o rodape                                  |
 *---------------------------------------------------------------------*/

Static Function fImpRod()
	Local nLinRod:= nLinFin + 10
	Local cTexto := ""

	//Linha Separatória
	oPrintPvt:Line(nLinRod, nColIni, nLinRod, nColFin)
	nLinRod += 3
	
	//Dados da Esquerda
	cTexto := "Or�amento: "+QRY_PED->CJ_NUM+"    |    "+dToC(dDataBase)+"     "+cHoraEx+"     "+FunName()+"     "+cUserName
	oPrintPvt:SayAlign(nLinRod, nColIni,    cTexto, oFontRod, 250, 07, , nPadLeft, )
	
	//Direita
	cTexto := "P�gina "+cValToChar(nPagAtu)
	oPrintPvt:SayAlign(nLinRod, nColFin-40, cTexto, oFontRod, 040, 07, , nPadRight, )
	
	//Finalizando a P�gina e somando mais um
	oPrintPvt:EndPage()
	nPagAtu++
Return

/*---------------------------------------------------------------------*
 | Func:  fLogoEmp                                                     |
 | Desc:  Funcao que retorna o logo da empresa (igual a DANFE)         |
 *---------------------------------------------------------------------*/

Static Function fLogoEmp()
	Local cGrpCompany := AllTrim(FWGrpCompany())
	Local cCodEmpGrp  := AllTrim(FWCodEmp())
	Local cUnitGrp    := AllTrim(FWUnitBusiness())
	Local cFilGrp     := AllTrim(FWFilial())
	Local cLogo       := ""
	Local cCamFim     := GetTempPath()
	Local cStart      := GetSrvProfString("Startpath", "")

	//Se tiver filiais por grupo de empresas
	If !Empty(cUnitGrp)
		cDescLogo	:= cGrpCompany + cCodEmpGrp + cUnitGrp + cFilGrp
		
	//Se nao, ser� apenas, empresa + filial
	Else
		cDescLogo	:= cEmpAnt + cFilAnt
	EndIf
	
	//Pega a imagem
	cLogo := cStart + "LGMID" + cDescLogo + ".PNG"
	
	//Se o arquivo Nao existir, pega apenas o da empresa, desconsiderando a filial
	If !File(cLogo)
		cLogo	:= cStart + "LGMID" + cEmpAnt + ".PNG"
	EndIf
	
	//Copia para a temporaria do s.o.
	CpyS2T(cLogo, cCamFim)
	cLogo := cCamFim + StrTran(cLogo, cStart, "")
	
	//Se o arquivo Nao existir na temporaria, espera meio segundo para terminar a c�pia
	If !File(cLogo)
		Sleep(500)
	EndIf
Return cLogo

/*---------------------------------------------------------------------*
 | Func:  fMudaLayout                                                  |
 | Desc:  Funcao que muda as variaveis das colunas do layout           |
 *---------------------------------------------------------------------*/

Static Function fMudaLayout()
	oFontRod   := TFont():New(cNomeFont, , -06, , .F.)
	oFontTit   := TFont():New(cNomeFont, , -15, , .T.)
	oFontCab   := TFont():New(cNomeFont, , -10, , .F.)
	oFontCabN  := TFont():New(cNomeFont, , -10, , .T.)
	
	If cLayout == "1"
		nPosCod  := 0010 //C�digo do Produto 
		nPosDesc := 0100 //Descricao
		nPosUnid := 0400 //Unidade de Medida
		nPosNCM  := 0435 //NCM
		nPosQuan := 0490 //Quantidade
		nPosVUni := 0530 //Valor Unitario
		nPosVTot := 0580 //Valor Total
		nPosSTVl := 0630 //Valor Unitario + ST
		nPosSTTo := 0680 //Valor Total ST
		nPosAIcm := 0730 //Aliquota ICMS
		nPosEnt  := 0780 //Entrega
		
		oFontDet   := TFont():New(cNomeFont, , -10, , .F.)
		oFontDetN  := TFont():New(cNomeFont, , -10, , .T.)
		
	Else
		nPosCod  := 0010 //C�digo do Produto 
		nPosDesc := 0100 //Descricao
		nPosUnid := 0400 //Unidade de Medida
		nPosNCM  := 0435 //NCM
		nPosQuan := 0490 //Quantidade
		nPosVUni := 0530 //Valor Unitario
		nPosVTot := 0580 //Valor Total
		nPosAIcm := 0650 //Aliquota ICMS
		nPosAIpi := 0690 //Aliquota IPI
		nPosEnt  := 0740 //Entrega
		
		oFontDet   := TFont():New(cNomeFont, , -10, , .F.)
		oFontDetN  := TFont():New(cNomeFont, , -10, , .T.)
	EndIf
Return

/*---------------------------------------------------------------------*
 | Func:  fImpTot                                                      |
 | Desc:  Funcao para imprimir os totais                               |
 *---------------------------------------------------------------------*/

Static Function fImpTot()
	nLinAtu += 7
	
	//Se atingir o fim da P�gina, quebra
	If nLinAtu + 50 >= nLinFin
		fImpRod()
		fImpCab()
	EndIf
	
	//Cria o grupo de Total
	oPrintPvt:Box(nLinAtu, nColIni, nLinAtu + 080, nColFin)
	oPrintPvt:Line(nLinAtu+nTamFundo, nColIni, nLinAtu+nTamFundo, nColFin)
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni+5, "Totais:",                                         oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinAtu += 7
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor do Frete: ",                                oFontCab,  080, 07, , nPadLeft,  )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotFrete, cMaskFrete)),         oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total dos Descontos: ",                     oFontCab,  150, 07, , nPadLeft,  )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nDesconto, cMaskVlr)),           oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total dos Produtos: ",                      oFontCab,  150, 07, , nPadLeft,  )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nValorTot, cMaskVlr)),           oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor do ICMS Substitui��o: ",                    oFontCab,  0150, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotalST, cMaskVlr)),            oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+005, "Valor do IPI:",                                    oFontCab,  080, 07, , nPadLeft,  )
	oPrintPvt:SayAlign(nLinAtu, nColIni+095, Alltrim(Transform(nTotIPI, cMaskVlr)),              oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total do Or�amento: ",                      oFontCab,  150, 07, , nPadLeft,  )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotVal, cMaskVlr)),             oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
Return

/*---------------------------------------------------------------------*
 | Func:  fMsgObs                                                      |
 | Desc:  Fun��o para imprimir mensagem de observa��o                  |
 *---------------------------------------------------------------------*/

Static Function fMsgObs()
Local cMsg      := ""
Local nTotCarac := 70
Local nLinMsg   := 0
Local nId       := 0
	
	nLinAtu += 008
	cMsg    := SCJ->CJ_XMSGI
	nLinMsg := MLCount(SCJ->CJ_XMSGI,nTotCarac)

	//Se atingir o fim da Pagina, quebra
	If nLinAtu + (nLinMsg*10) >= nLinFin
		fImpRod()
		fImpCab()
	EndIf

	//Cria o grupo de Observa��o
	oPrintPvt:SayAlign(nLinAtu, nColIni, "Observa��es: ",   oFontTit,  100, nTamFundo, nCorAzul, nPadLeft, )
	nLinAtu += 015
	
	For nId := 1 To nLinMsg
		oPrintPvt:SayAlign(nLinAtu, nColIni, MemoLine(cMsg,nTotCarac,nId),    oFontCab,  540, 07, , nPadLeft, )
	nLinAtu += 008
	Next nId
	nLinAtu += 010

Return
