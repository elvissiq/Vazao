#Include "PROTHEUS.CH"
#Include "TBICONN.CH"
#Include "TbiCode.ch"
#Include "TopConn.CH"
#Include "Ap5mail.ch"

/*/{protheusDoc.marcadores_ocultos} ACOMW054
  Função ACOMW054
  @parâmetro : pDados - array com os dados da nota fiscal de entrada
                 [1] - Série da Nota Fiscal
                 [2] - Número da Nota Fiscal
                 [3] - Código do fornecedor
                 [4] - Loja do fornecedor 
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // ACOMW054 - Workflow para liberação do Documento de Entrada
  Return
  @historia
  23/02/2021 - Desenvolvimento da Rotina.
/*/
User Function ACOMW054(nOpcao,oProcess,pDados)
  Local aArea := GetArea()

  Private cSerSF1 := ""
  Private cDocSF1 := ""
  Private cForSF1 := ""
  Private cLojSF1 := ""

  If Empty(nOpcao)
     Default nOpcao := 0
     Default pDados := {"","","",""}
  EndIf 

  If nOpcao == 3
     cSerSF1 := pDados[1]
     cDocSF1 := pDados[2]
     cForSF1 := pDados[3]
     cLojSF1 := pDados[4]
  EndIf 

  Do Case
     Case nOpcao == 0
          U_ApvDEIni()
          
     Case nOpcao == 3
          U_ApvDEIni()
          
     Case nOpcao == 1
          U_apvDERet(oProcess)
          
     Case nOpcao == 2
          U_ApvDETOut(oProcess)
  EndCase

  RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW054
  Função ApvDEIni

  @sample
 // ApvDEIni - Esta função é responsável por iniciar a criação do
               processo e por enviar a mensagem para o destinatário.
  Return
  @historia
  23/02/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function ApvDEIni()
  Local nCont    := 0
  Local cQuery   := ""
  Local cQualDif := ""
  Local aAprovDE := {}
  Local aDados   := {}

 // --- Verificar a Nota Fiscal bloqueada
 // -------------------------------------
  cQuery := "Select SD1.D1_COD, SD1.D1_UM, SD1.D1_QUANT, SD1.D1_VUNIT, SD1.D1_TOTAL,"
  cQuery += "       SD1.D1_DTDIGIT, SD1.D1_CC, SD1.D1_EMISSAO, SC7.C7_QUANT, SC7.C7_UM,"
  cQuery += "       SC7.C7_PRECO, SC7.C7_TOTAL, SC7.C7_EMISSAO, SC7.C7_CC, SC7.C7_NUM,"
  cQuery += "       SC7.C7_LOCAL, SA2.A2_NREDUZ, SB1.B1_DESC"
  cQuery += "  from " + RetSqlName("SD1") + " SD1, " + RetSqlName("SC7") + " SC7, "
  cQuery += RetSqlName("SA2") + " SA2, " + RetSqlName("SB1") + " SB1"
  cQuery += "   where SD1.D_E_L_E_T_ <> '*'"
  cQuery += "     and SD1.D1_FILIAL  = '" + FWxFilial("SD1") + "'"
  cQuery += "     and SD1.D1_DOC     = '" + cDocSF1 + "'"
  cQuery += "     and SD1.D1_SERIE   = '" + cSerSF1 + "'"
  cQuery += "     and SD1.D1_FORNECE = '" + cForSF1 + "'"
  cQuery += "     and SD1.D1_LOJA    = '" + cLojSF1 + "'"
  cQuery += "     and SC7.D_E_L_E_T_ <> '*'"
  cQuery += "     and SC7.C7_FILIAL  = '" + FWxFilial("SC7") + "'"
  cQuery += "     and SC7.C7_NUM     = SD1.D1_PEDIDO"
  cQuery += "     and SC7.C7_ITEM    = SD1.D1_ITEMPC"
  cQuery += "     and (SC7.C7_QUANT <> SD1.D1_QUANT"
  cQuery += "       or SC7.C7_PRECO <> SD1.D1_VUNIT"
  cQuery += "       or SC7.C7_TOTAL <> SD1.D1_TOTAL)"
  cQuery += "     and SA2.D_E_L_E_T_ <> '*'"
  cQuery += "     and SA2.A2_FILIAL  = '" + FWxFilial("SA2") + "'"
  cQuery += "     and SA2.A2_COD     = '" + cForSF1 + "'"
  cQuery += "     and SA2.A2_LOJA    = '" + cLojSF1 + "'"
  cQuery += "     and SB1.D_E_L_E_T_ <> '*'"
  cQuery += "     and SB1.B1_FILIAL  = '" + FWxFilial("SB1") + "'"
  cQuery += "     and SB1.B1_COD     = SD1.D1_COD"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSF1",.F.,.T.)

  MemoWrite("C:\Temp\ATAN.sql",cQuery)

  While ! QSF1->(Eof())
    cQualDif := ""

    If QSF1->C7_QUANT <> QSF1->D1_QUANT
       cQualDif += "Q"
    EndIf

    If QSF1->C7_PRECO <> QSF1->D1_VUNIT
       cQualDif += "P"
    EndIf

    If QSF1->C7_TOTAL <> QSF1->D1_TOTAL
       cQualDif += "T"
    EndIf
    
    aAdd(aDados,{FWEmpName(cEmpAnt),;                 // 01 - Nome Empresa
                 FWFilialName(),;                     // 02 - Nome Filial
                 cForSF1 + "-" + QSF1->A2_NREDUZ,;    // 03 - Código - Nome do Fornecedor
                 cLojSF1,;                            // 04 - Loja do Fornecedor
                 QSF1->C7_LOCAL,;                     // 05 - Almoxarifado
                 cSerSF1,;                            // 06 - Série da Nota Fiscal 
                 cDocSF1,;                            // 07 - Número da Nota Fiscal 
                 QSF1->C7_NUM,;                       // 08 - Pedido de Compras
                 SToD(QSF1->D1_EMISSAO),;             // 09 - Emissão da Nota
                 QSF1->D1_COD,;                       // 10 - Código do Produto
                 QSF1->B1_DESC,;                      // 11 - Descrição do Produto
                 QSF1->D1_UM,;                        // 12 - Unidade de medida
                 QSF1->D1_QUANT,;                     // 13 - Quantidade na Nota
                 QSF1->D1_VUNIT,;                     // 14 - Valor unitário na Nota
                 QSF1->D1_TOTAL,;                     // 15 - Total na Nota
                 SToD(QSF1->D1_DTDIGIT),;             // 16 - Data da digitação
                 QSF1->D1_CC,;                        // 17 - Centro de Custo na Nota
                 QSF1->C7_UM,;                        // 18 - Unidade de medida no Pedido
                 QSF1->C7_QUANT,;                     // 19 - Quantidade no Pedido
                 QSF1->C7_PRECO,;                     // 20 - Preço unitário no Pedido
                 QSF1->C7_TOTAL,;                     // 21 - Total no Pedido
                 SToD(QSF1->C7_EMISSAO),;             // 22 - Emissão do Pedido
                 QSF1->C7_CC,;                        // 23 - Centro de Custo no Pedido
                 cQualDif})                           // 24 - Tipo diferente: 'Q' - Quantidade,'P'- Preço e 'T' - Total

    QSF1->(dbSkip())
  EndDo

  QSF1->(dbCloseArea())
  
  If Len(aDados) == 0
     ApMsgInfo("Nota Fiscal de Entrada não tem divergência com o Pedido de Compra.")
   else
     dbSelectArea("SF1")
     SF1->(dbSelectArea(1))
     SF1->(dbSeek(FWxFilial("SF1") + cDocSF1 + cSerSF1 + cForSF1 + cLojSF1))

     aAprovDE := fnW54Apv(cDocSF1 + cSerSF1 + cForSF1 + cLojSF1)

     For nCont := 1 To Len(aAprovDE)
         fnW54Mail(aAprovDE[nCont], aDados)
     Next nCont
  EndIf   
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW054
  Função fnW54Mail

  @sample
 // fnW54Mail - Envia e-mail para os aprovadores. 

  Return
  @historia
  23/02/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
Static Function fnW54Mail(aEnvPara, aDados)
  Local nDias      := 30
  Local nHoras     := 0
  Local nMinutos   := 0
  Local nId        := 0
  Local cClickPara := ""
  Local cServWF    := ""
  Local cBarras    := If(isSRVunix(),"/","\")

  Local cCdStatus, cHtmlModelo, cMailID
  Local cTexto, cAssunto

  Private oProcess := Nil

  cClickPara  := "Documento Entrada Divergente"
  cCdStatus   := "100100"  
  cServWF     := GetMv("MV_XURLWF")
  cHtmlModelo := cBarras + "workflow" + cBarras + "desblode_reg.htm"
  cAssunto    := "Aprovação Documento Entrada Divergente - " + cSerSF1 + "/" + cDocSF1
 
  oProcess := TWFProcess():New("00001", cAssunto)
  oProcess:NewTask(cAssunto, cHtmlModelo)

  ConOut("(INICIO|APVPC)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

  cTexto    := "Iniciando o processo de " + cAssunto + " N: " + cSerSF1 + "/" + cDocSF1
  cCdStatus := "100100"                         // Código do cadastro de status de processo
  cTexto    := "Gerando solicitação para envio..."
  cCdStatus := "100200"

  oProcess:oHtml:ValByName("D1_FILIAL" , aDados[01][02])
  oProcess:oHtml:ValByName("cAprovador", aEnvPara[02]) 
  oProcess:oHtml:ValByName("D1_FORNECE", aDados[01][03])
  oProcess:oHtml:ValByName("D1_LOJA"   , aDados[01][04])
  oProcess:oHtml:ValByName("cAlmox"    , aDados[01][05])
  oProcess:oHtml:ValByName("D1_SERIE"  , aDados[01][06])
  oProcess:oHtml:ValByName("D1_DOC"    , aDados[01][07])
  oProcess:oHtml:ValByName("D1_PEDIDO" , aDados[01][08])
  oProcess:oHtml:ValByName("D1_EMISSAO", DToC(aDados[01][09]))

  For nId := 1 To Len(aDados)
      aAdd(oProcess:oHtml:ValByName("it.PRODUTO"), aDados[nId][10])
      aAdd(oProcess:oHtml:ValByName("it.DESCRI") , aDados[nId][11])
      aAdd(oProcess:oHtml:ValByName("it.UM")     , aDados[nId][12])

      If At("Q",aDados[nId][24]) > 0
         aAdd(oProcess:oHtml:ValByName("it.QUANT"), "<b><font color='red'>" +;
                             Transform(aDados[nId][13],"@E 999,999,999.99") + "</font></b>")
       else
         aAdd(oProcess:oHtml:ValByName("it.QUANT"), Transform(aDados[nId][13],"@E 999,999,999.99"))
      EndIf

      If At("P",aDados[nId][24]) > 0
         aAdd(oProcess:oHtml:ValByName("it.VUNIT"), "<b><font color='red'>" +;
                             Transform(aDados[nId][14],"@E 999,999,999.99") + "</font></b>")
       else
         aAdd(oProcess:oHtml:ValByName("it.VUNIT"), Transform(aDados[nId][14],"@E 999,999,999.99"))
      EndIf

      If At("T",aDados[nId][24]) > 0
         aAdd(oProcess:oHtml:ValByName("it.VTOTAL"), "<b><font color='red'>" +;
                             Transform(aDados[nId][15],"@E 999,999,999.99") + "</font></b>")
       else
         aAdd(oProcess:oHtml:ValByName("it.VTOTAL"), Transform(aDados[nId][15],"@E 999,999,999.99"))
      EndIf

      aAdd(oProcess:oHtml:ValByName("it.DIGIT")  , DToC(aDados[nId][16]))
      aAdd(oProcess:oHtml:ValByName("it.CCUSTO") , aDados[nId][17])

      aAdd(oProcess:oHtml:ValByName("tp.PRODUTO") , aDados[nId][10])
      aAdd(oProcess:oHtml:ValByName("tp.DESCRI")  , aDados[nId][11])
      aAdd(oProcess:oHtml:ValByName("tp.UM")      , aDados[nId][18])

      If At("Q",aDados[nId][24]) > 0
         aAdd(oProcess:oHtml:ValByName("tp.QUANT"), "<b><font color='red'>" +;
                             Transform(aDados[nId][19],"@E 999,999,999.99") + "</font></b>")
       else
         aAdd(oProcess:oHtml:ValByName("tp.QUANT"), Transform(aDados[nId][19],"@E 999,999,999.99"))
      EndIf

      If At("P",aDados[nId][24]) > 0
         aAdd(oProcess:oHtml:ValByName("tp.PRECO"), "<b><font color='red'>" +;
                             Transform(aDados[nId][20],"@E 999,999,999.99") + "</font></b>")
       else
         aAdd(oProcess:oHtml:ValByName("tp.PRECO"), Transform(aDados[nId][20],"@E 999,999,999.99"))
      EndIf

      If At("T",aDados[nId][24]) > 0
         aAdd(oProcess:oHtml:ValByName("tp.VTOTALPD"), "<b><font color='red'>" +;
                             Transform(aDados[nId][21],"@E 999,999,999.99") + "</font></b>")
       else
         aAdd(oProcess:oHtml:ValByName("tp.VTOTALPD"), Transform(aDados[nId][21],"@E 999,999,999.99"))
      EndIf

      aAdd(oProcess:oHtml:ValByName("tp.EMISSAO") , DToC(aDados[nId][22]))
      aAdd(oProcess:oHtml:ValByName("tp.CCUSTO")  , aDados[nId][23])
  Next
  
  oProcess:cSubject := cAssunto
  oProcess:cTo      := "apvde"
  oProcess:bReturn  := "U_ACOMW054(1)"

 // Informe o nome da função do tipo timeout que será executada se houver um timeout
 // ocorrido para esse processo. Neste exemplo, será executada 5 minutos após o envio
 // do e-mail para o destinatário. Caso queira-se aumentar ou diminuir o tempo, altere
 // os valores das variáveis: nDias, nHoras e nMinutos.
  oProcess:bTimeOut := {{"U_ACOMW054(2)", nDias, nHoras, nMinutos}}

  cMailID := oProcess:Start()

  cHtmlModelo := cBarras + "workflow" + cBarras + "desblode_msg.htm"

  oProcess:NewTask(cAssunto, cHtmlModelo)

  ConOut("(INICIO|WFLINK)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

  oProcess:cSubject := cAssunto
  oProcess:cTo      := aEnvPara[05]

  oProcess:ohtml:ValByName("cEmpresa", aDados[01][01])	         //-- Descricacao do Processo (Apresentada na Guia do Navegador)
  oProcess:ohtml:ValByName("cFilial" , aDados[01][02])		       //-- Descricacao do Processo (Apresentada na Guia do Navegador)
  oProcess:ohtml:ValByName("cNumNF"  , cSerSF1 + "/" + cDocSF1)  //-- Descricacao do Processo (Apresentado no CORPO do formulario)
  oProcess:ohtml:ValByName("cNumPD"  , aDados[01][08])           //-- Descricao do Cabeçalho de identificação do Destinatario
  oProcess:ohtml:ValByName("cFornece", aDados[01][03])           //-- Nome do Fornecedor
  oProcess:ohtml:ValByName("cEmissao", DToC(aDados[01][09]))     //-- Data Emissão da Nota

 // --- Mensagem do Click aqui para ....
 // ------------------------------------
  oProcess:ohtml:ValByName("LinkExt"  , cClickPara)	         //-- Mensagem do Link de remessa para contacao
  oProcess:ohtml:ValByName("proc_link", "http://" + cServWf + "apvde/" + cMailID + ".htm")

 // --- Adicione informacao a serem incluidas na rastreabilidade
 // ------------------------------------------------------------
  cTexto    := "Enviando solicitação..."
  cCdStatus := "100300"

  oProcess:Start()

  cTexto    := "Aguardando retorno..."
  cCdStatus := "100400"
  
  ApMsgAlert("E-Mail enviado com sucesso...","ATENÇÃO")
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW054
  Função ApvDERet

  @sample
 // ApvDERet - Esta função é executada no retorno da mensagem enviada
               pelo destinatário. O Workflow recria o processo em que
               parou anteriormente na funcao APVInicio e repassa a
               variável objeto oProcess por parâmetro.
  Return
  @historia
  23/02/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function ApvDERet(oProcess)
  Local cOpc     := ""
  Local cDocto   := ""
  Local cObsBlq  := " "
  Local cCdStatus, cTexto

  Conout("(RETORNO)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID)

 // --- Obtenha o número da nota
 // ----------------------------
  cForSF1 := Substr(oProcess:oHtml:RetByName("D1_FORNECE"),1,TamSX3("A2_COD")[1])
  cLojSF1 := PadR(AllTrim(oProcess:oHtml:RetByName("D1_LOJA")),TamSX3("D1_LOJA")[1])
  cSerSF1 := PadR(AllTrim(oProcess:oHtml:RetByName("D1_SERIE")),TamSX3("D1_SERIE")[1])
  cDocSF1 := PadR(AllTrim(oProcess:oHtml:RetByName("D1_DOC")),TamSX3("D1_DOC")[1])
  cObsBlq := oProcess:oHtml:RetByName("cMOTIVO")

 // --- Opção para confimrar ou não a aprovação "cAPROV" por ser:
 // ---   L = Aprovado chama rotina 'A097ProcLib', opção = 2 
 // ---   R = Rejeitado que correspondente a '3' na rotina de liberação
 // ------------------------------------------------------------------- 
  cOpc := oProcess:oHtml:RetByName("cAPROV")

  cDocto := cDocSF1 + cSerSF1 + cForSF1 + cLojSF1

 // --- Posiciona-se no Registro de Liberacao do APROVADOR
 // ------------------------------------------------------
  dbSelectArea("SCR")
  SCR->(dbSetorder(3)) 			// Codigo do Aprovador
  SCR->(dbSeek(FWxFilial("SCR") + "NF" + PadR(cDocto,TamSX3("CR_NUM")[1]) +;
               PadR(AllTrim(oProcess:oHtml:RetByName("cAprovador")),TamSX3("CR_APROV")[1])))
             
  If cOpc == "L"              
     A097ProcLib(SCR->(Recno()),2,SCR->CR_TOTAL,SCR->CR_APROV,SCR->CR_GRUPO,cObsBlq,dDataBase)    // Liberar

     dbSelectArea("SF1")
     SF1->(dbSetOrder(1))

     If SF1->(dbSeek(FWxFilial("SF1") + cDocSF1 + cSerSF1 + cForSF1 + cLojSF1))
        Reclock("SF1",.F.)
          Replace SF1->F1_STATUS with ""
        SF1->(MsUnlock())
     EndIf
  else
     MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,,SCR->CR_APROV,,SCR->CR_GRUPO,,,,dDataBase,cObsBlq},dDataBase,7,,,,,,,"") // Bloquear documento
  EndIf

  // --- Mensagem no console
  // --- L - Liberou
  // --- R - Rejeitado
  // -----------------------
   Do Case
      Case cOpc == "L"                                    
           ConOut(" ==> Documento de Entrada Liberado  " + cDocto)
      
           cMsgSol := ", foi LIBERADO."
      
      Case cOpc == "R"
           ConOut(" ==> Documento de Entrada Bloqueado " + cDocto)
      
           cMsgSol := ", foi REJEITADO."
   EndCase

   ConOut(" ==> WF DOCUMENTO ENTRADA (RETORNO de aprovação - Fim): " + cDocto)
 
  // --- Adicione informacao a serem incluidas na rastreabilidade
  // ------------------------------------------------------------
   cTexto    := "Finalizando o processo..."
   cCdStatus := "200800"                       
Return

//-----------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} fnW54Apv
  Constroi vetor com dados dos aprovadores do Docto de Entrada
  Passado como parametros

  @parâmetros: cDocApv - Codigo do documento de entrada para
                         Liberação.

  sample
 // fnW54Apv - Pegar os aprovadores

  Return: aAprovador - Vetor com os dados dos Aprovedores do Documento
                       de entrada para Liberacao Descritos em 
                       SCR - Doc's por alcada, sendo:
                        aAprovador[01] - Codigo do Grupo de Aprovadores
                        aAprovador[02] - Codigo do Aprovador
                        aAprovador[03] - Codigo do usuario correspondete
                        aAprovador[04] - Nome
                        aAprovador[05] - Endereco de e-mail
                        aAprovador[06] - Tipo de Aprovacao (Liberacao
                                         ou Visto)
                        aAprovador[07] - "S" ou "N" Considera Limites
                        aAprovador[08] - 
                         Tipo de Liberacao:
                          "U" - Usuario - Libera apenas seu usuario
                          "N" - Pode Liberar todo o nivel a que este 
                                pertence
                          "P" - Libera todo o documento, independente de 
                                outras aprovacoes, autonomia total.
  @historia
  23/02/2021 - Desenvolvimento da Rotina.
/*/
Static Function fnW54Apv(cDocApv)
  Local aInfo      := {}
  Local aAprovador := {}

  dbSelectArea("SCR")
  SCR->(dbSetorder(1))
  SCR->(dbSeek(xFilial("SCR") + "NF" + cDocApv))

 // --- Loop em documentacao p/alçada para verificar
 // --- quem deve aprovar a liberacao.
 // ------------------------------------------------
  While !(SCR->(Eof())) .and. SCR->CR_FILIAL == FWxFilial("SCR") .and. SCR->CR_TIPO == "NF" .and.;
        Alltrim(SCR->CR_NUM) == cDocApv
    dbSelectArea("SAL")
    SAL->(dbSetorder(3))
    SAL->(dbSeek(xFilial("SAL") + SF1->F1_APROV + SCR->CR_APROV))
	
   // --- Verifica se esta aguardando liberacao e monta
   // --- o ventor com os aprovadores do Grupo.
   // -------------------------------------------------
    PswOrder(1)
 
    If Val(SCR->CR_STATUS) == 2 .and. PswSeek(SCR->CR_USER,.T.)
       aInfo := PswRet(1)
      
      // Monta vetor dos aprovadores {[Grupo de Apr.],[Aprovador],[USuario],[Nome],[e-mail],[Tipo de Aprovacao],[Considera Limites],[Tipo Lib.]}
		   aAdd(aAprovador, {SCR->CR_GRUPO,;
                         SCR->CR_APROV,;
                         SCR->CR_USER,;
                         aInfo[1,2],;
                         AllTrim(aInfo[1,14]),;
                         SAL->AL_LIBAPR,;
                         SAL->AL_AUTOLIM,;
                         SAL->AL_TPLIBER})
    Endif
    
    SCR->(dbSkip())
  Enddo
Return aAprovador
