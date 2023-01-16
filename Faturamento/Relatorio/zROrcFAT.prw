//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"

//Variaveis utilizadas no fonte inteiro
Static nPadLeft   := 0                                                                     //Alinhamento a Esquerda
Static nPadRight  := 1                                                                     //Alinhamento a Direita
Static nPadCenter := 2                                                                     //Alinhamento Centralizado
Static nPosCod    := 0000                                                                  //Posição Inicial da Coluna de Cídigo do Produto 
Static nPosDesc   := 0000                                                                  //Posição Inicial da Coluna de Descrição
Static nPosUnid   := 0000                                                                  //Posição Inicial da Coluna de Unidade de Medida
Static nPosQuan   := 0000                                                                  //Posição Inicial da Coluna de Quantidade
Static nPosVUni   := 0000                                                                  //Posição Inicial da Coluna de Valor Unitario
Static nPosVTot   := 0000                                                                  //Posição Inicial da Coluna de Valor Total
Static nPosBIcm   := 0000                                                                  //Posição Inicial da Coluna de Base Calculo ICMS
Static nPosVIcm   := 0000                                                                  //Posição Inicial da Coluna de Valor ICMS
Static nPosVIPI   := 0000                                                                  //Posição Inicial da Coluna de Valor Ipi
Static nPosAIcm   := 0000                                                                  //Posição Inicial da Coluna de Aliquota ICMS
Static nPosAIpi   := 0000                                                                  //Posição Inicial da Coluna de Aliquota IPI
Static nPosSTUn   := 0000                                                                  //Posição Inicial da Coluna de Valor Unitírio ST
Static nPosSTVl   := 0000                                                                  //Posição Inicial da Coluna de Valor Unitírio + ST
Static nPosSTBa   := 0000                                                                  //Posição Inicial da Coluna de Base do ST
Static nPosSTTo   := 0000                                                                  //Posição Inicial da Coluna de Valor Total ST
Static nTamFundo  := 15                                                                    //Altura de fundo dos blocos com título
Static cEmpEmail  := Alltrim(SuperGetMV("MV_X_EMAIL", .F., "email@empresa.com.br"))        //Parímetro com o e-Mail da empresa
Static cEmpSite   := Alltrim(SuperGetMV("MV_X_HPAGE", .F., "http://www.empresa.com.br"))   //Parímetro com o site da empresa
Static nCorAzul   := RGB(89, 111, 117)                                                     //Cor Azul usada nos Títulos
Static cNomeFont  := "Arial"                                                               //Nome da Fonte Padrío
Static oFontDet   := Nil                                                                   //Fonte utilizada na Impressão dos itens
Static oFontDetN  := Nil                                                                   //Fonte utilizada no cabeÃ§alho dos itens
Static oFontRod   := Nil                                                                   //Fonte utilizada no rodape da Página
Static oFontTit   := Nil                                                                   //Fonte utilizada no Título das seções
Static oFontCab   := Nil                                                                   //Fonte utilizada na Impressão dos textos dentro das seções
Static oFontCabN  := Nil                                                                   //Fonte negrita utilizada na Impressão dos textos dentro das seções
Static cMaskPad   := "@E 999,999.99"                                                       //Míscara padrío de valor 
Static cMaskTel   := "@R (99)9999-9999"                                                    //Míscara de telefone / fax
Static cMaskCNPJ  := "@R 99.999.999/9999-99"                                               //Míscara de CNPJ
Static cMaskCEP   := "@R 99999-999"                                                        //Míscara de CEP
Static cMaskCPF   := "@R 999.999.999-99"                                                   //Míscara de CPF
Static cMaskQtd   := PesqPict("SCK", "CK_QTDVEN")                                          //Míscara de quantidade
Static cMaskPrc   := PesqPict("SCK", "CK_PRCVEN")                                          //Míscara de preío
Static cMaskVlr   := PesqPict("SCK", "CK_VALOR")                                           //Míscara de valor
Static cMaskFrete := PesqPict("SCJ", "CJ_FRETE")                                           //Míscara de frete

/*/{Protheus.doc} zROrcFAT
Impressão Grafica generica de Orçamento de Venda (em pdf)
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
	//Variaveis usadas nas outras funçães
	Private cLogoEmp := fLogoEmp()
	Private cPedDe   := SCJ->CJ_NUM
	Private cPedAt   := SCJ->CJ_NUM
	Private cLayout  := "1"
	Private cTipoBar := "3"
	Private cImpDupl := "1"
	Private cZeraPag := "1"
	
	//Adiciona os parâmetro para a pergunta
	aAdd(aPergs, {1, "Orçamento De",  cPedDe, "", ".T.", "SCJ", ".T.", 80, .T.})
	aAdd(aPergs, {1, "Orçamento Ate", cPedAt, "", ".T.", "SCJ", ".T.", 80, .T.})
	aAdd(aPergs, {2, "Layout",                         Val(cLayout),  {"1=Dados com ST",     "2=Dados com IPI"},                                       100, ".T.", .F.})
	aAdd(aPergs, {2, "Código de Barras",               Val(cTipoBar), {"1=Número do Orçamento", "2=Filial + Número do Orçamento", "3=Sem Código de Barras"}, 100, ".T.", .F.})
	aAdd(aPergs, {2, "Imprimir Previsão Duplicatas",   Val(cImpDupl), {"1=Sim",              "2=Nao"},                                                 100, ".T.", .F.})
	aAdd(aPergs, {2, "Zera a Página ao trocar Orçamento", Val(cZeraPag), {"1=Sim",              "2=Nao"},                                                 100, ".T.", .F.})
	
	//Se a pergunta for confirmada
	If ParamBox(aPergs, "Informe os parâmetro", @aRetorn, , , , , , , , .F., .F.)
		cPedDe   := aRetorn[1]
		cPedAt   := aRetorn[2]
		cLayout  := cValToChar(aRetorn[3])
		cTipoBar := cValToChar(aRetorn[4])
		cImpDupl := cValToChar(aRetorn[5])
		cZeraPag := cValToChar(aRetorn[6])
		
		//FunÃ§Ã£o que muda alinhamento e fontes
		fMudaLayout()
		
		//Chama o processamento do relatório
		oProcess := MsNewProcess():New({|| fMontaRel(@oProcess) }, "Impressão Orçamento de Venda", "Processando", .F.)
		oProcess:Activate()
	EndIf
	
	RestArea(aAreaC5)
	RestArea(aArea)
Return

/*---------------------------------------------------------------------*
 | Func:  fMontaRel                                                    |
 | Desc:  FunÃ§Ã£o principal que monta o relatório                       |
 *---------------------------------------------------------------------*/

Static Function fMontaRel(oProc)
	//Variaveis usada no controle das ríguas
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
	//Variaveis do relatório
	Local cNomeRel      := "Orcamento_venda_"+FunName()+"_"+RetCodUsr()+"_"+dToS(Date())+"_"+StrTran(Time(), ":", "-")
	Private oPrintPvt
	Private cHoraEx     := Time()
	Private nPagAtu     := 1
	Private aDuplicatas := {}
	//Linhas e colunas
	Private nLinAtu     := 0
	Private nLinFin     := 780
	Private nColIni     := 010
	Private nColFin     := 550
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
	
	//Criando o objeto de Impressão
	oPrintPvt := FWMSPrinter():New(cNomeRel, IMP_PDF, .F., /*cStartPath*/, .T., , @oPrintPvt, , , , , .T.)
	oPrintPvt:cPathPDF := GetTempPath()
	oPrintPvt:SetResolution(72)
	oPrintPvt:SetPortrait()
	oPrintPvt:SetPaperSize(DMPAPER_A4)
	oPrintPvt:SetMargin(60, 60, 60, 60)
	
	//Selecionando os Orçamentos
	cQryPed := " SELECT "                                        + CRLF
	cQryPed += "    CJ_FILIAL, "                                 + CRLF
	cQryPed += "    CJ_NUM, "                                    + CRLF
	cQryPed += "    CJ_EMISSAO, "                                + CRLF
	cQryPed += "    CJ_CLIENTE, "                                + CRLF
	cQryPed += "    CJ_LOJA, "                                   + CRLF
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
	cQryPed += "    ISNULL(A4_NREDUZ, '') AS A4_NREDUZ, "        + CRLF
	cQryPed += "    CJ_XVEND1, "                                 + CRLF
	cQryPed += "    ISNULL(A3_NREDUZ, '') AS A3_NREDUZ, "        + CRLF
	cQryPed += "    CJ_TPFRETE, "                                + CRLF
	cQryPed += "    CJ_FRETE, "                                  + CRLF
	cQryPed += "    CJ_XOBS, "                                   + CRLF
	cQryPed += "    SCJ.R_E_C_N_O_ AS CJREC "                    + CRLF
	cQryPed += " FROM "                                          + CRLF
	cQryPed += "    "+RetSQLName("SCJ")+" SCJ "                  + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SA1")+" SA1 ON ( "   + CRLF
	cQryPed += "        A1_FILIAL   = '"+FWxFilial("SA1")+"' "   + CRLF
	cQryPed += "        AND A1_COD  = SCJ.CJ_CLIENTE "           + CRLF
	cQryPed += "        AND A1_LOJA = SCJ.CJ_LOJA "              + CRLF
	cQryPed += "        AND SA1.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SE4")+" SE4 ON ( "   + CRLF
	cQryPed += "        E4_FILIAL     = '"+FWxFilial("SE4")+"' " + CRLF
	cQryPed += "        AND E4_CODIGO = SCJ.CJ_CONDPAG "         + CRLF
	cQryPed += "        AND SE4.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SA4")+" SA4 ON ( "   + CRLF
	cQryPed += "        A4_FILIAL  = '"+FWxFilial("SA4")+"' "    + CRLF
	cQryPed += "        AND SA4.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SA3")+" SA3 ON ( "   + CRLF
	cQryPed += "        A3_FILIAL  = '"+FWxFilial("SA3")+"' "    + CRLF
	cQryPed += "        AND A3_COD = SCJ.CJ_XVEND1 "              + CRLF
	cQryPed += "        AND SA3.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += " WHERE "                                         + CRLF
	cQryPed += "    CJ_FILIAL   = '"+FWxFilial("SCJ")+"' "       + CRLF
	cQryPed += "    AND CJ_NUM >= '"+cPedDe+"' "                 + CRLF
	cQryPed += "    AND CJ_NUM <= '"+cPedAt+"' "                 + CRLF
	cQryPed += "    AND SCJ.D_E_L_E_T_ = ' ' "                   + CRLF
	TCQuery cQryPed New Alias "QRY_ORC"
	TCSetField("QRY_ORC", "CJ_EMISSAO", "D")
	Count To nTotPed
	oProc:SetRegua1(nTotPed)
	
	//Somente se houver Orçamentos
	If nTotPed != 0
	
		//Enquanto houver Orçamentos
		QRY_ORC->(DbGoTop())
		While ! QRY_ORC->(EoF())
			If cZeraPag == "1"
				nPagAtu := 1
			EndIf
			nPedAtu++
			oProc:IncRegua1("Processando o Orçamento "+cValToChar(nPedAtu)+" de "+cValToChar(nTotPed)+"...")
			oProc:SetRegua2(1)
			oProc:IncRegua2("...")
			
			//Imprime o cabeÃ§alho
			fImpCab()
			
			//Inicializa os calculos de impostos
			nItAtu   := 0
			nTotIte  := 0
			nTotalST := 0
			nTotIPI  := 0
			SCJ->(DbGoTo(QRY_ORC->CJREC))
			MaFisIni(SCJ->CJ_CLIENTE,;                   // 01 - Código Cliente/Fornecedor
				SCJ->CJ_LOJA,;                           // 02 - Loja do Cliente/Fornecedor
				Iif(SCJ->CJ_TIPO $ "D;B", "F", "C"),;    // 03 - C:Cliente , F:Fornecedor
				SCJ->CJ_TIPO,;                           // 04 - Tipo da NF
				SCJ->CJ_TIPOCLI,;                        // 05 - Tipo do Cliente/Fornecedor
				MaFisRelImp("MT100", {"SF2", "SD2"}),;   // 06 - Relacao de Impostos que suportados no arquivo
				,;                                       // 07 - Tipo de complemento
				,;                                       // 08 - Permite Incluir Impostos no Rodape .T./.F.
				"SB1",;                                  // 09 - Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
				"MATA461")                               // 10 - Nome da rotina que esta utilizando a funcao
			
			//Seleciona agora os itens do Orçamento
			cQryIte := " SELECT "                                      + CRLF
			cQryIte += "    CK_PRODUTO, "                              + CRLF
			cQryIte += "    ISNULL(B1_DESC, '') AS B1_DESC, "          + CRLF
			cQryIte += "    CK_UM, "                                   + CRLF
			cQryIte += "    CK_ENTREG, "                               + CRLF
			cQryIte += "    CK_TES, "                                  + CRLF
			cQryIte += "    CK_QTDVEN, "                               + CRLF
			cQryIte += "    CK_PRCVEN, "                               + CRLF
			cQryIte += "    CK_VALDESC, "                              + CRLF
			cQryIte += "    CK_VALOR "                                 + CRLF
			cQryIte += " FROM "                                        + CRLF
			cQryIte += "    "+RetSQLName("SCK")+" SCK "                + CRLF
			cQryIte += "    LEFT JOIN "+RetSQLName("SB1")+" SB1 ON ( " + CRLF
			cQryIte += "        B1_FILIAL = '"+FWxFilial("SB1")+"' "   + CRLF
			cQryIte += "        AND B1_COD = SCK.CK_PRODUTO "          + CRLF
			cQryIte += "        AND SB1.D_E_L_E_T_ = ' ' "             + CRLF
			cQryIte += "    ) "                                        + CRLF
			cQryIte += " WHERE "                                       + CRLF
			cQryIte += "    CK_FILIAL = '"+FWxFilial("SCK")+"' "       + CRLF
			cQryIte += "    AND CK_NUM = '"+QRY_ORC->CJ_NUM+"' "       + CRLF
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
				MaFisAdd(QRY_ITE->CK_PRODUTO,;    // 01 - Código do Produto                    ( Obrigatorio )
					QRY_ITE->CK_TES,;             // 02 - Código do TES                        ( Opcional )
					QRY_ITE->CK_QTDVEN,;          // 03 - Quantidade                           ( Obrigatorio )
					QRY_ITE->CK_PRCVEN,;          // 04 - Preco Unitario                       ( Obrigatorio )
					QRY_ITE->CK_VALDESC,;         // 05 - Desconto
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
			//MaFisAlt("NF_DESPESA", SCJ->CJ_D
			//ESPESA) 
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
				nValSol    := (MaFisRet(nItAtu, "IT_VALSOL") / QRY_ITE->CK_QTDVEN) 
				nBasSol    := MaFisRet(nItAtu, "IT_BASESOL")
				nPrcUniSol := QRY_ITE->CK_PRCVEN + nValSol
				nTotSol    := nPrcUniSol * QRY_ITE->CK_QTDVEN
				nTotalST   += MaFisRet(nItAtu, "IT_VALSOL")
				nTotIPI    += nValIPI
				
				//Imprime os dados
				If cLayout == "1"
					oPrintPvt:SayAlign(nLinAtu, nPosCod, QRY_ITE->CK_PRODUTO,                                oFontDet, 040, 35, , nPadLeft, )
					oPrintPvt:SayAlign(nLinAtu, nPosDesc, QRY_ITE->B1_DESC,                                  oFontDet, 200, 07, , nPadLeft, )
					oPrintPvt:SayAlign(nLinAtu, nPosQuan, Alltrim(Transform(QRY_ITE->CK_QTDVEN, cMaskQtd)),  oFontDet, 025, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosVUni, Alltrim(Transform(QRY_ITE->CK_PRCVEN, cMaskPrc)),  oFontDet, 035, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosSTUn, Alltrim(Transform(nValSol, cMaskPad)),             oFontDet, 025, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosSTVl, Alltrim(Transform(nPrcUniSol, cMaskPrc)),          oFontDet, 025, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosSTBa, Alltrim(Transform(nBasSol, cMaskPad)),             oFontDet, 025, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosSTTo, Alltrim(Transform(nTotSol, cMaskVlr)),             oFontDet, 050, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosVTot, Alltrim(Transform(QRY_ITE->CK_VALOR, cMaskVlr)),   oFontDet, 050, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosBIcm, Alltrim(Transform(nBasICM, cMaskPad)),             oFontDet, 025, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosVIcm, Alltrim(Transform(nValICM, cMaskPad)),             oFontDet, 025, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosAIcm, Alltrim(Transform(nAlqICM, cMaskPad)),             oFontDet, 025, 07, , nPadRight, )
				Else
					oPrintPvt:SayAlign(nLinAtu, nPosCod, QRY_ITE->CK_PRODUTO,                                oFontDet, 040, 07, , nPadLeft, )
					oPrintPvt:SayAlign(nLinAtu, nPosDesc, QRY_ITE->B1_DESC,                                  oFontDet, 200, 07, , nPadLeft, )
					oPrintPvt:SayAlign(nLinAtu, nPosUnid, QRY_ITE->CK_UM,                                    oFontDet, 030, 07, , nPadLeft, )
					oPrintPvt:SayAlign(nLinAtu, nPosQuan, Alltrim(Transform(QRY_ITE->CK_QTDVEN, cMaskQtd)),  oFontDet, 030, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosVUni, Alltrim(Transform(QRY_ITE->CK_PRCVEN, cMaskPrc)),  oFontDet, 030, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosVTot, Alltrim(Transform(QRY_ITE->CK_VALOR, cMaskVlr)),   oFontDet, 060, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosBIcm, Alltrim(Transform(nBasICM, cMaskPad)),             oFontDet, 030, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosVIcm, Alltrim(Transform(nValICM, cMaskPad)),             oFontDet, 030, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosVIPI, Alltrim(Transform(nValIPI, cMaskPad)),             oFontDet, 030, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosAIcm, Alltrim(Transform(nAlqICM, cMaskPad)),             oFontDet, 030, 07, , nPadRight, )
					oPrintPvt:SayAlign(nLinAtu, nPosAIpi, Alltrim(Transform(nAlqIPI, cMaskPad)),             oFontDet, 030, 07, , nPadRight, )
				EndIf
				//nLinAtu += 7
				nLinAtu += 10
				
				//Se por acaso atingiu o limite da página, finaliza, e começa uma nova página
				If nLinAtu >= nLinFin
					fImpRod()
					fImpCab()
				EndIf
				
				nValorTot += QRY_ITE->CK_VALOR
				QRY_ITE->(DbSkip())
			EndDo
			nTotFrete := MaFisRet(, "NF_FRETE")
			nTotVal := MaFisRet(, "NF_TOTAL")
			fMontDupl()
			QRY_ITE->(DbCloseArea())
			MaFisEnd()
			
			//Imprime o total do Orçamento
			fImpTot()
			
			//Se tiver mensagem da observação
			If !Empty(QRY_ORC->CJ_XOBS)
				fMsgObs()
			EndIf
			
			//Se deverí ser impresso as duplicatas
			If cImpDupl == "1"
				fImpDupl()
			EndIf
			
			//Imprime o rodapé
			fImpRod()
			
			QRY_ORC->(DbSkip())
		EndDo
		
		//Gera o pdf para visualização
		oPrintPvt:Preview()
	
	Else
		MsgStop("Nao há Orçamentos!", "Atenção")
	EndIf
	QRY_ORC->(DbCloseArea())
Return

/*---------------------------------------------------------------------*
 | Func:  fImpCab                                                      |
 | Desc:  FunÃ§Ã£o que imprime o cabeÃ§alho                               |
 *---------------------------------------------------------------------*/

Static Function fImpCab()
	Local cTexto      := ""
	Local nLinCab     := 025
	Local nLinCabOrig := nLinCab
	Local cCodBar     := ""
	Local nColMeiPed  := nColMeio+8+((nColMeio-nColIni)/2)
	Local lCNPJ       := (QRY_ORC->A1_PESSOA != "F")
	Local cCliAux     := QRY_ORC->CJ_CLIENTE+" "+QRY_ORC->CJ_LOJA+" - "+QRY_ORC->A1_NOME
	Local cCGC        := ""
	Local cFretePed   := ""
	//Dados da empresa
	Local cEmpresa    := Iif(Empty(SM0->M0_NOMECOM), Alltrim(SM0->M0_NOME), Alltrim(SM0->M0_NOMECOM))
	Local cEmpTel     := Alltrim(Transform(SubStr(SM0->M0_TEL, 2, Len(SM0->M0_TEL)), cMaskTel))
	Local cEmpFax     := Alltrim(Transform(SubStr(SM0->M0_FAX, 2, Len(SM0->M0_FAX)), cMaskTel))
	Local cEmpCidade  := AllTrim(SM0->M0_CIDENT)+" / "+SM0->M0_ESTENT
	Local cEmpCnpj    := Alltrim(Transform(SM0->M0_CGC, cMaskCNPJ))
	Local cEmpCep     := Alltrim(Transform(SM0->M0_CEPENT, cMaskCEP))
	
	//Iniciando Página
	oPrintPvt:StartPage()
	
	//Dados da Empresa
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + 120, nColMeio-3)
	oPrintPvt:Line(nLinCab+nTamFundo, nColIni, nLinCab+nTamFundo, nColMeio-3)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColIni+5, "Emitente:",                                      oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayBitmap(nLinCab+3, nColIni+5, cLogoEmp, 054, 054)
	oPrintPvt:SayAlign(nLinCab,    nColIni+65, "Empresa:",                                      oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColIni+95, cEmpresa,                                        oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "CNPJ:",                                          oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+87, cEmpCnpj,                                         oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Cidade:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+95, cEmpCidade,                                       oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "CEP:",                                           oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+85, cEmpCep,                                          oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Telefone:",                                      oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+95, cEmpTel,                                          oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Telefone:",                                           oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+95, cEmpFax,                                          oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "e-Mail:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+87, cEmpEmail,                                        oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Site:",                                     		oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+80, cEmpSite,                                        	oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	
	//Dados do Orçamento
	nLinCab := nLinCabOrig
	oPrintPvt:Box(nLinCab, nColMeio+3, nLinCab + 120, nColFin)
	oPrintPvt:Line(nLinCab+nTamFundo, nColMeio+3, nLinCab+nTamFundo, nColFin)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColMeio+8,  "Orçamento:",                                 	oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Num.Orçamento:",                              	oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+62, QRY_ORC->CJ_NUM,                                oFontCab,  060, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Dt.Emissao:",                                  oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+50, dToC(QRY_ORC->CJ_EMISSAO),                      oFontCab,  060, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Cliente:",                                     oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+34, cCliAux,                                        oFontCab, 200, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Nome Fantasia:",                               oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+64, QRY_ORC->A1_NREDUZ,  	                        oFontCab, 200, 07, , nPadLeft, )
	nLinCab += 9
	cCGC := QRY_ORC->A1_CGC
	If lCNPJ
		cCGC := Iif(!Empty(cCGC), Alltrim(Transform(cCGC, cMaskCNPJ)), "-")
		oPrintPvt:SayAlign(nLinCab, nColMeio+8, "CNPJ:",                                        oFontCabN, 060, 07, , nPadLeft, )
	Else
		cCGC := Iif(!Empty(cCGC), Alltrim(Transform(cCGC, cMaskCPF)), "-")
		oPrintPvt:SayAlign(nLinCab, nColMeio+8, "CPF:",                                         oFontCabN, 060, 07, , nPadLeft, )
	EndIf
	oPrintPvt:SayAlign(nLinCab, nColMeio+32, cCGC,                                              oFontCab,  060, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Telefone:",	                                    oFontCabN, 035, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+037,"("+QRY_ORC->A1_DDD+")",							oFontCab,  039, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+050,QRY_ORC->A1_TEL,	 								oFontCab,  190, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "E-mail:",		                                    oFontCabN, 030, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+032, QRY_ORC->A1_EMAIL,		 						oFontCab,  170, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Endereco:",	                                    oFontCabN, 040, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+042, QRY_ORC->A1_END,			 						oFontCab,  170, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Bairro, Cidade - UF: ",                             oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+070, Alltrim(QRY_ORC->A1_BAIRRO),						oFontCab,  130, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+140,", "+Alltrim(QRY_ORC->A1_MUN),						oFontCab,  180, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+190," - "+Alltrim(QRY_ORC->A1_EST),					oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Vendedor:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+44, QRY_ORC->CJ_XVEND1 + " "+QRY_ORC->A3_NREDUZ,       oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 9
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Frete:",                                           oFontCabN, 060, 07, , nPadLeft, )
	If QRY_ORC->CJ_TPFRETE == "C"
		cFretePed := "CIF"
	ElseIf QRY_ORC->CJ_TPFRETE == "F"
		cFretePed := "FOB"
	ElseIf QRY_ORC->CJ_TPFRETE == "T"
		cFretePed := "Terceiros"
	Else
		cFretePed := "Sem Frete"
	EndIf
	cFretePed += " - "+Alltrim(Transform(QRY_ORC->CJ_FRETE, cMaskFrete))
	oPrintPvt:SayAlign(nLinCab, nColMeio+28, cFretePed,                                         oFontCab,  060, 07, , nPadLeft, )
	
	//Código de barras
	nLinCab := nLinCabOrig
	If cTipoBar $ "1;2"
		If cTipoBar == "1"
			cCodBar := QRY_ORC->CJ_NUM
		ElseIf cTipoBar == "2"
			cCodBar := QRY_ORC->CJ_FILIAL+QRY_ORC->CJ_NUM
		EndIf
		oPrintPvt:Code128C(nLinCab+90+nTamFundo, nColFin-60, cCodBar, 28)
		oPrintPvt:SayAlign(nLinCab+92+nTamFundo, nColFin-60, cCodBar, oFontRod, 080, 07, , nPadLeft, )
	EndIf

	//TÃ­tulo
	nLinCab := nLinCabOrig + 125
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + nTamFundo, nColFin)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColIni, "Relatório de Orçamentos de Venda:", oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	
	//Linha SeparatÃ³rio
	nLinCab += 6
	
	//cabeÃ§alho com descrÃ§Ã£o das colunas
	nLinCab += 3
	If cLayout == "1"
		oPrintPvt:SayAlign(nLinCab, nPosCod,  "Cod.Prod.", oFontDetN, 035, 07, , nPadLeft, )
		oPrintPvt:SayAlign(nLinCab, nPosDesc, "Descricao", oFontDetN, 200, 07, , nPadLeft, )
		oPrintPvt:SayAlign(nLinCab, nPosQuan, "Quant.",    oFontDetN, 025, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosVUni, "Vl.Unit.",  oFontDetN, 025, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosSTUn, "Vl.ST",     oFontDetN, 025, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosSTVl, "Vlr + ST",  oFontDetN, 025, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosSTBa, "BC.ST",     oFontDetN, 025, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosVTot, "Vl.Total",  oFontDetN, 050, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosSTTo, "Vl.Tot.ST", oFontDetN, 050, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosBIcm, "BC.ICMS",   oFontDetN, 025, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosVIcm, "Vl.ICMS",   oFontDetN, 025, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosAIcm, "A.ICMS",    oFontDetN, 025, 07, , nPadRight, )
	Else
		oPrintPvt:SayAlign(nLinCab, nPosCod, "Cod.Prod.",  oFontDetN, 040, 07, , nPadLeft, )
		oPrintPvt:SayAlign(nLinCab, nPosDesc, "Descricao", oFontDetN, 200, 07, , nPadLeft, )
		oPrintPvt:SayAlign(nLinCab, nPosUnid, "Uni.Med.",  oFontDetN, 030, 07, , nPadLeft, )
		oPrintPvt:SayAlign(nLinCab, nPosQuan, "Quant.",    oFontDetN, 030, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosVUni, "Vl.Unit.",  oFontDetN, 030, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosVTot, "Vl.Total",  oFontDetN, 060, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosBIcm, "BC.ICMS",   oFontDetN, 030, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosVIcm, "Vl.ICMS",   oFontDetN, 030, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosVIPI, "Vl.IPI",    oFontDetN, 030, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosAIcm, "A.ICMS",    oFontDetN, 030, 07, , nPadRight, )
		oPrintPvt:SayAlign(nLinCab, nPosAIpi, "A.IPI",     oFontDetN, 030, 07, , nPadRight, )
	EndIf
	
	//Atualizando a linha inicial do relatório
	nLinAtu := nLinCab + 8
Return

/*---------------------------------------------------------------------*
 | Func:  fImpRod                                                      |
 | Desc:  FunÃ§Ã£o que imprime o rodape                                  |
 *---------------------------------------------------------------------*/

Static Function fImpRod()
	Local nLinRod:= nLinFin + 10
	Local cTexto := ""

	//Linha SeparatÃ³ria
	oPrintPvt:Line(nLinRod, nColIni, nLinRod, nColFin)
	nLinRod += 3
	
	//Dados da Esquerda
	cTexto := "Orçamento: "+QRY_ORC->CJ_NUM+"    |    "+dToC(dDataBase)+"     "+cHoraEx+"     "+FunName()+"     "+cUserName
	oPrintPvt:SayAlign(nLinRod, nColIni,    cTexto, oFontRod, 250, 07, , nPadLeft, )
	
	//Direita
	cTexto := "Página "+cValToChar(nPagAtu)
	oPrintPvt:SayAlign(nLinRod, nColFin-40, cTexto, oFontRod, 040, 07, , nPadRight, )
	
	//Finalizando a Página e somando mais um
	oPrintPvt:EndPage()
	nPagAtu++
Return

/*---------------------------------------------------------------------*
 | Func:  fLogoEmp                                                     |
 | Desc:  FunÃ§Ã£o que retorna o logo da empresa (igual a DANFE)         |
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
		
	//SeNao, serÃ¡ apenas, empresa + filial
	Else
		cDescLogo	:= cEmpAnt + cFilAnt
	EndIf
	
	//Pega a imagem
	cLogo := cStart + "LGMID" + cDescLogo + ".PNG"
	
	//Se o arquivo Nao existir, pega apenas o da empresa, desconsiderando a filial
	If !File(cLogo)
		cLogo	:= cStart + "LGMID" + cEmpAnt + ".PNG"
	EndIf
	
	//Copia para a temporÃ¡ria do s.o.
	CpyS2T(cLogo, cCamFim)
	cLogo := cCamFim + StrTran(cLogo, cStart, "")
	
	//Se o arquivo Nao existir na temporíria, espera meio segundo para terminar a cÃ³pia
	If !File(cLogo)
		Sleep(500)
	EndIf
Return cLogo

/*---------------------------------------------------------------------*
 | Func:  fMudaLayout                                                  |
 | Desc:  FunÃ§Ã£o que muda as variÃ¡veis das colunas do layout           |
 *---------------------------------------------------------------------*/

Static Function fMudaLayout()
	oFontRod   := TFont():New(cNomeFont, , -06, , .F.)
	oFontTit   := TFont():New(cNomeFont, , -13, , .T.)
	oFontCab   := TFont():New(cNomeFont, , -07, , .F.)
	oFontCabN  := TFont():New(cNomeFont, , -07, , .T.)
	
	If cLayout == "1"
		nPosCod  := 0010 //Código do Produto 
		nPosDesc := 0045 //Descricao
		nPosQuan := 0245 //Quantidade
		nPosVUni := 0270 //Valor Unitario
		nPosSTUn := 0295 //Valor UnitÃ¡rio ST
		nPosSTVl := 0320 //Valor UnitÃ¡rio + ST
		nPosSTBa := 0345 //Base do ST
		nPosVTot := 0370 //Valor Total
		nPosSTTo := 0420 //Valor Total ST
		nPosBIcm := 0470 //Base Calculo ICMS
		nPosVIcm := 0495 //Valor ICMS
		nPosAIcm := 0520 //Aliquota ICMS
		
		oFontDet   := TFont():New(cNomeFont, , -06, , .F.)
		oFontDetN  := TFont():New(cNomeFont, , -06, , .T.)
		
	Else
		nPosCod  := 0010 //Código do Produto 
		nPosDesc := 0050 //Descricao
		nPosUnid := 0250 //Unidade de Medida
		nPosQuan := 0280 //Quantidade
		nPosVUni := 0310 //Valor Unitario
		nPosVTot := 0340 //Valor Total
		nPosBIcm := 0400 //Base Calculo ICMS
		nPosVIcm := 0430 //Valor ICMS
		nPosVIPI := 0460 //Valor Ipi
		nPosAIcm := 0490 //Aliquota ICMS
		nPosAIpi := 0520 //Aliquota IPI
		
		oFontDet   := TFont():New(cNomeFont, , -07, , .F.)
		oFontDetN  := TFont():New(cNomeFont, , -07, , .T.)
	EndIf
Return

/*---------------------------------------------------------------------*
 | Func:  fImpTot                                                      |
 | Desc:  FunÃ§Ã£o para imprimir os totais                               |
 *---------------------------------------------------------------------*/

Static Function fImpTot()
	nLinAtu += 4
	
	//Se atingir o fim da Página, quebra
	If nLinAtu + 50 >= nLinFin
		fImpRod()
		fImpCab()
	EndIf
	
	//Cria o grupo de Total
	oPrintPvt:Box(nLinAtu, nColIni, nLinAtu + 045, nColFin)
	oPrintPvt:Line(nLinAtu+nTamFundo, nColIni, nLinAtu+nTamFundo, nColFin)
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni+5, "Totais:",                                         oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinAtu += 5
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor do Frete: ",                                oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotFrete, cMaskFrete)),         oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total dos Produtos: ",                      oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nValorTot, cMaskVlr)),           oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor do ICMS Substituição: ",                    oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotalST, cMaskVlr)),            oFontCabN, 080, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+005, "Valor do IPI:",                                   oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+095, Alltrim(Transform(nTotIPI, cMaskVlr)),             oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total do Orçamento: ",                         oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotVal, cMaskVlr)),             oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
Return

/*---------------------------------------------------------------------*
 | Func:  fMsgObs                                                      |
 | Desc:  FunÃ§Ã£o para imprimir mensagem de observação                  |
 *---------------------------------------------------------------------*/

Static Function fMsgObs()
	Local aMsg  := {"", "", ""}
	Local nQueb := 100
	Local cMsg  := Alltrim(QRY_ORC->CJ_XOBS)
	nLinAtu += 4
	
	//Se atingir o fim da Página, quebra
	If nLinAtu + 40 >= nLinFin
		fImpRod()
		fImpCab()
	EndIf
	
	//Quebrando a mensagem
	If Len(cMsg) > nQueb
		aMsg[1] := SubStr(cMsg,    1, nQueb)
		aMsg[1] := SubStr(aMsg[1], 1, RAt(' ', aMsg[1]))
		
		//Pegando o restante e adicionando nas outras linhas
		cMsg := Alltrim(SubStr(cMsg, Len(aMsg[1])+1, Len(cMsg)))
		If Len(cMsg) > nQueb
			aMsg[2] := SubStr(cMsg,    1, nQueb)
			aMsg[2] := SubStr(aMsg[2], 1, RAt(' ', aMsg[2]))
			
			cMsg := Alltrim(SubStr(cMsg, Len(aMsg[2])+1, Len(cMsg)))
			aMsg[3] := cMsg
		Else
			aMsg[2] := cMsg
		EndIf
	Else
		aMsg[1] := cMsg
	EndIf
	
	//Cria o grupo de observação
	oPrintPvt:Box(nLinAtu, nColIni, nLinAtu + 038, nColFin)
	oPrintPvt:Line(nLinAtu+nTamFundo, nColIni, nLinAtu+nTamFundo, nColFin)
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni+5, "Observacao:",                oFontTit,  100, nTamFundo, nCorAzul, nPadLeft, )
	nLinAtu += 5
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, aMsg[1],                      oFontCab,  400, 07, , nPadLeft, )
	nLinAtu += 7
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, aMsg[2],                      oFontCab,  400, 07, , nPadLeft, )
	nLinAtu += 7
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, aMsg[3],                      oFontCab,  400, 07, , nPadLeft, )
	nLinAtu += 10
Return

/*---------------------------------------------------------------------*
 | Func:  fMontDupl                                                    |
 | Desc:  FunÃ§Ã£o que monta o array de duplicatas                       |
 *---------------------------------------------------------------------*/

Static Function fMontDupl()
	Local aArea    := GetArea()
	Local lDtEmi   := SuperGetMv("MV_DPDTEMI", .F., .T.)
	Local nAcerto  := 0
	Local aEntr    := {}
	Local aDupl    := {}
	Local aDuplTmp := {}
	Local nItem    := 0
	Local nAux     := 0
	
	aDuplicatas := {}
	
	//Posiciona na condiÃ§Ã£o de pagamento
	DbSelectarea("SE4")
	SE4->(DbSetOrder(1))
	SE4->(DbSeek(xFilial("SE4")+SCJ->CJ_CONDPAG))
	
	//Se na planilha financeira do Orçamento de Venda as duplicatas serÃ£o separadas pela Emissao
	If lDtEmi
		//Se Nao for do tipo 9
		If (SE4->E4_TIPO != "9")
			//Pega as datas e valores das duplicatas
			aDupl := Condicao(MaFisRet(, "NF_BASEDUP"), SCJ->CJ_CONDPAG, MaFisRet(, "NF_VALIPI"), SCJ->CJ_EMISSAO, MaFisRet(, "NF_VALSOL"))
			
			//Se tiver dados, percorre os valores e adiciona dados na Ãºltima parcela
			If Len(aDupl) > 0
				For nAux := 1 To Len(aDupl)
					nAcerto += aDupl[nAux][2]
				Next nAux
				aDupl[Len(aDupl)][2] += MaFisRet(, "NF_BASEDUP") - nAcerto
			EndIf
		
		//Adiciona uma Ãºnica linha
		Else
			aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
		EndIf
		
	Else
		//Percorre os itens
		nItem := 0
		QRY_ITE->(DbGoTop())
		While ! QRY_ITE->(EoF())
			nItem++
			
			//Se tiver entrega
			If !Empty(QRY_ITE->CK_ENTREG)
				
				//Procura pela data de entrega no Array
				nPosEntr := Ascan(aEntr, {|x| x[1] == QRY_ITE->CK_ENTREG})
				
				//Se Nao encontrar cria a Linha, do contrÃ¡rio atualiza os valores
 				If nPosEntr == 0
					aAdd(aEntr, {QRY_ITE->CK_ENTREG, MaFisRet(nItem, "IT_BASEDUP"), MaFisRet(nItem, "IT_VALIPI"), MaFisRet(nItem, "IT_VALSOL")})
				Else
					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_BASEDUP")
					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_VALIPI")
					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_VALSOL")
				EndIf
			EndIf
			
			QRY_ITE->(DbSkip())
		EndDo
		
		//Se Nao for CondiÃ§Ã£o do tipo 9
		If (SE4->E4_TIPO != "9")
			
			//Percorre os valores conforme data de entrega
			For nItem := 1 to Len(aEntr)
				nAcerto  := 0
				aDuplTmp := Condicao(aEntr[nItem][2], SCJ->CJ_CONDPAG, aEntr[nItem][3], aEntr[nItem][1], aEntr[nItem][4])
				
				//Atualiza o valor da Ãºltima parcela
				For nAux := 1 To Len(aDuplTmp)
					nAcerto += aDuplTmp[nAux][2]
				Next nAux
				aDuplTmp[Len(aDuplTmp)][2] += aEntr[nItem][2] - nAcerto
				
				//Percorre o temporÃ¡rio e adiciona no duplicatas
				aEval(aDuplTmp, {|x| aAdd(aDupl, {aEntr[nItem][1], x[1], x[2]})})
			Next
			
		Else
	    	aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
		EndIf
	EndIf
	
	//Se Nao tiver duplicatas, adiciona em branco
	If Len(aDupl) == 0
		aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
	EndIf
	
	aDuplicatas := aClone(aDupl)
	RestArea(aArea)
Return

/*---------------------------------------------------------------------*
 | Func:  fImpDupl                                                     |
 | Desc:  FunÃ§Ã£o para imprimir as duplicatas                           |
 *---------------------------------------------------------------------*/

Static Function fImpDupl()
	Local nLinhas 		:= NoRound(Len(aDuplicatas)/2, 0) + 1
	Local nAtual  		:= 0
	Local nLinDup 		:= 0
	Local nLinLim 		:= nLinAtu + ((nLinhas+1)*7) + nTamFundo
	Local nColAux 		:= nColIni
	nLinAtu += 4
	
	//Se atingir o fim da Página, quebra
	If nLinLim+5 >= nLinFin
		fImpRod()
		fImpCab()
	EndIf
	
	// CondiÃ§Ã£o de Pagamento
	oPrintPvt:Box(nLinAtu, nColIni, nLinAtu + nTamFundo, nColFin)
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni, "Condicao de Pagamento:  " +QRY_ORC->E4_DESCRI, 									oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	
	nLinAtu += 5

	//Cria o grupo de Duplicatas
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni+5,  "Duplicatas",                													oFontTit,  100, nTamFundo, nCorAzul, nPadLeft, )
	nLinAtu += 5
	nLinDup := nLinAtu

	//Percorre as duplicatas
	For nAtual := 1 To Len(aDuplicatas)
		oPrintPvt:SayAlign(nLinDup, nColAux+0005, StrZero(nAtual, 3)+", no dia "+dToC(aDuplicatas[nAtual][1])+":", 				oFontCab,  080, 07, , nPadLeft, )
		oPrintPvt:SayAlign(nLinDup, nColAux+0095, Alltrim(Transform(aDuplicatas[nAtual][2], cMaskVlr)),            				oFontCabN, 080, 07, , nPadRight, )
		nLinDup += 7
		
		//Se atingiu o Número de linhas, muda para imprimir na coluna do meio
		If nAtual == nLinhas
			nLinDup := nLinAtu
			nColAux := nColMeio
		EndIf
	Next

	nLinAtu += (nLinhas*7) + 3
	nLinAtu += 3
	oPrintPvt:Line(nLinDup+nTamFundo, nColIni+3, nLinDup+nTamFundo, nColFin)
Return
