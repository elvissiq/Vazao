#Include "PROTHEUS.ch"
#Include "AP5MAIL.ch"
#Include "TBICONN.ch"

/*/{protheusDoc.marcadores_ocultos} ACOMW057
  Função ACOMW057
  @parâmetro nOpcao - opção de execução: 0 = Execução, 1 e 2 = Retorno
             oProcess - objeto do processo
             pCotacao - Número do Pedido de Compras

  @author Totvs Nordeste - Anderson Almeida
  @sample
 // ACOMW057 - Workflow para envio de aprovação de Pedido de Compras
  Return
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
User Function ACOMW057(nOpcao,oProcess,pNumPC)
  Local aArea := GetArea()

  Private cNumPC := ""
  
  If Empty(nOpcao)
     Default nOpcao := 0
  EndIf 

  Do Case
     Case nOpcao == 3
          cNumPC := pNumPC
          U_ApvPcIni()
          
     Case nOpcao == 1
          U_apvPcRet(oProcess)
          
     Case nOpcao == 2
          U_ApvPcTOut(oProcess)
  EndCase

  RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW057
  Função ApvPCIni

  @sample
 // ApvPCIni - Esta função é responsável por iniciar a criação do
               processo e por enviar a mensagem para o destinatário. 

  Return
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function ApvPcIni()
  Local nCont    := 0
  Local aAprovPC := {}
  Local aDados   := {}

 // --- Pegar dados do Pedido de Compras
 // ------------------------------------
  If SC7->C7_CONAPRO <> "B"
     ApMsgAlert("Pedido de Compra não encontra-se bloqueado.","ATENÇÃO")
     Return
  EndIf

  While ! SC7->(Eof()) .and. SC7->C7_FILIAL == FWxFilial("SC7") .and. SC7->C7_NUM == cNumPC
    aAdd(aDados,{FWEmpName(cEmpAnt),;                    // 01 - Nome Empresa
                 SC7->C7_NUM,;                           // 02 - Número do Pedido de Compras
                 UsrFullName(SC7->C7_USER),;             // 03 - Nome do solicitante
                 SC7->C7_EMISSAO,;                       // 04 - Emissão da Solicitação de Compras
                 SC7->C7_ITEM,;                          // 05 - Item da Solicitação de Compras 
                 SC7->C7_PRODUTO,;                       // 06 - Produto
                 SC7->C7_DESCRI,;                        // 07 - Descrição do produto
                 SC7->C7_UM,;                            // 08 - Unidade de medida do produto
                 SC7->C7_QUANT,;                         // 09 - Quantidade do produto
                 SC7->C7_PRECO,;                         // 10 - Data da preferencial da entrega do produto
                 SC7->C7_TOTAL,;                         // 11 - Valor total
                 SC7->C7_VLDESC,;                        // 12 - Valor do desconto
                 SC7->C7_VALFRE,;                        // 13 - Valor do frete
                 SC7->C7_CONTATO,;                       // 14 - Contato do fornecedor
                 SC7->C7_OBS,;                           // 15 - Observação
                 FWFilialName()})                        // 16 - Nome da filial

    SC7->(dbSkip())
  EndDo

  aAprovPC := fnW57Apv(cNumPC)

  If Len(aAprovPC) == 0
     ApMsgAlert("E-Mail não enviado por que não existe Aprovadores.")
   else  
     For nCont := 1 To Len(aAprovPC)
         fnW57Mail(aAprovPC[nCont], aDados)
     Next nCont
  EndIf   
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW057
  Função fnW57Mail

  @sample
 // fnW57Mail - Envia e-mail para os aprovadores. 

  Return
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
Static Function fnW57Mail(aEnvPara, aDados)
  Local nDias      := 30
  Local nHoras     := 0
  Local nMinutos   := 0
  Local nId        := 0
  Local nSubTotal  := 0
  Local nDscTotal  := 0
  Local nFreTotal  := 0
  Local nPedTotal  := 0
  Local cClickPara := ""
  Local cServWF    := ""
  Local cBarras    := If(isSRVunix(),"/","\")
  
  Local cCdStatus, cHtmlModelo, cMailID
  Local cTexto, cAssunto

  Private oProcess := Nil

  cClickPara  := "Pedido de Compra"
  cCdStatus   := "100200"  
  cServWF     := GetMv("MV_XURLWF")
  cHtmlModelo := cBarras + "workflow" + cBarras + "aprovapc_reg.htm"
  cAssunto    := "Aprovação Pedido de Compra - " + cNumPC
 
  oProcess := TWFProcess():New("00001", cAssunto)
  oProcess:NewTask(cAssunto, cHtmlModelo)

  ConOut("(INICIO|APVPC)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

  cTexto    := "Iniciando o processo de " + cAssunto + " N: " + cNumPC
  cCdStatus := "100201"                         // Código do cadastro de status de processo
  cTexto    := "Gerando solicitação para envio..."
  cCdStatus := "100202"

  oProcess:oHtml:ValByName("cFilial"  , FWFilialName())
  oProcess:oHtml:ValByName("cNUM"     , aDados[01][02])
  oProcess:oHtml:ValByName("cSOLICIT" , aDados[01][03]) 
  oProcess:oHtml:ValByName("cEMISSAO" , aDados[01][04])
  oProcess:oHtml:ValByName("cNOMAPROV", aEnvPara[04])
  oProcess:oHtml:ValByName("cCODAPROV", aEnvPara[02])

  For nId := 1 To Len(aDados)
      aAdd(oProcess:oHtml:ValByName("it.ITEM")   , aDados[nId][05])
      aAdd(oProcess:oHtml:ValByName("it.PRODUTO"), aDados[nId][07])
      aAdd(oProcess:oHtml:ValByName("it.DESCRI") , aDados[nId][07])
      aAdd(oProcess:oHtml:ValByName("it.UM")     , aDados[nId][08])
      aAdd(oProcess:oHtml:ValByName("it.QUANT")  , Transform(aDados[nId][09],"@E 999,999,999.99"))
      aAdd(oProcess:oHtml:ValByName("it.PRECO")  , Transform(aDados[nId][10],"@E 999,999,999.99"))
      aAdd(oProcess:oHtml:ValByName("it.TOTAL")  , Transform(aDados[nId][11],"@E 999,999,999.99"))

      nSubTotal += aDados[nId][11]
      nDscTotal += aDados[nId][12]
      nFreTotal += aDados[nId][13]
  Next

  nPedTotal := (nSubTotal - nDscTotal) + nFreTotal

  oProcess:oHtml:ValByName("c7_filent", AllTrim(SM0->M0_ENDENT) + " - " +;
                                        AllTrim(SM0->M0_CIDENT) + " / " +;
                                        AllTrim(SM0->M0_ESTENT))
  oProcess:oHtml:ValByName("SUBTOTAL" , Transform(nSubTotal,"@E 999,999,999.99"))
  oProcess:oHtml:ValByName("VLDESC"   , Transform(nDscTotal,"@E 999,999,999.99"))
  oProcess:oHtml:ValByName("VALFRETE" , Transform(nFreTotal,"@E 999,999,999.99"))
  oProcess:oHtml:ValByName("TOTPEDIDO", Transform(nPedTotal,"@E 999,999,999.99"))

	oProcess:oHtml:ValByName("C7_CONTATO", aDados[01][14])
	oProcess:oHtml:ValByName("C7_OBS"    , aDados[01][15])
  
  oProcess:cSubject := cAssunto
  oProcess:cTo      := "apvpc"
  oProcess:bReturn  := "U_ACOMW057(1)"

 // Informe o nome da função do tipo timeout que será executada se houver um timeout
 // ocorrido para esse processo. Neste exemplo, será executada 5 minutos após o envio
 // do e-mail para o destinatário. Caso queira-se aumentar ou diminuir o tempo, altere
 // os valores das variáveis: nDias, nHoras e nMinutos.
  oProcess:bTimeOut := {{"U_ACOMW057(2)", nDias, nHoras, nMinutos}}

  cMailID := oProcess:Start()

  cHtmlModelo := cBarras + "workflow" + cBarras + "aprovapc_msg.htm"

  oProcess:NewTask(cAssunto, cHtmlModelo)

  ConOut("(INICIO|WFLINK)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

  oProcess:cSubject := cAssunto
  oProcess:cTo      := aEnvPara[05]

  oProcess:ohtml:ValByName("cNomAprov"   , aEnvPara[04])
  oProcess:ohtml:ValByName("cEmpresa"    , aDados[01][01])
  oProcess:ohtml:ValByName("cFilial"     , aDados[01][16])
  oProcess:ohtml:ValByName("cNumero"     , aDados[01][02])
  oProcess:ohtml:ValByName("cSolicitante", aDados[01][03])
  oProcess:ohtml:ValByName("cCodAprov"   , aEnvPara[02])
  oProcess:ohtml:ValByName("cTelefone"   , "(87) 3848-2500")

 // --- Mensagem do Click aqui para ....
 // ------------------------------------
  oProcess:ohtml:ValByName("LinkExt",cClickPara)
  oProcess:ohtml:ValByName("proc_link","http://" + cServWF + "apvpc/" + cMailID + ".htm")

 // ---- Adicione informacao a serem incluidas na rastreabilidade
  cTexto    := "Enviando solicitação..."
  cCdStatus := "100203"

  oProcess:Start()

  cTexto    := "Aguardando retorno..."
  cCdStatus := "100204"
  
  ApMsgAlert("E-Mail enviado com sucesso...","ATENÇÃO")
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW057
  Função ApvPCRet

  @sample
 // ApvPCRet - Esta função é executada no retorno da mensagem enviada
               pelo destinatário. O Workflow recria o processo em que
               parou anteriormente na funcao APVInicio e repassa a
               variável objeto oProcess por parâmetro.
  Return
  @historia
  03/03/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function ApvPCRet(oProcess)
  Local nOpc    := 0
  Local cObsBlq := " "
  Local cNumSC7 := ""
  Local cCdStatus, cTexto

  Conout("(RETORNO)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID)

  cNumSC7 := oProcess:oHtml:RetByName("cNUM")
  cObsBlq := oProcess:oHtml:RetByName("cMOTIVO")

 // --- Opção para confimrar ou não a aprovação "cAPROV" por ser:
 // ---   L = Aprovado que correspondente a '2' na rotina de liberação 
 // ---   R = Rejeitado que correspondente a '3' na rotina de liberação
 // ------------------------------------------------------------------- 
  nOpc := IIf(oProcess:oHtml:RetByName("cAPROV") == "L",2,3) 

 // --- Posiciona-se no Registro de Liberacao do APROVADOR
 // ------------------------------------------------------
  dbSelectArea("SCR")
  SCR->(dbSetorder(3)) 			// Codigo do Aprovador
  
  If ! SCR->(dbSeek(FWxFilial("SCR") + "IP" + PadR(cNumSC7,TamSX3("CR_NUM")[1]) +;
               PadR(AllTrim(oProcess:oHtml:RetByName("cCodAprov")),TamSX3("CR_APROV")[1])))
     If ! SCR->(dbSeek(FWxFilial("SCR") + "PC" + PadR(cNumSC7,TamSX3("CR_NUM")[1]) +;
                       PadR(AllTrim(oProcess:oHtml:RetByName("cCodAprov")),TamSX3("CR_APROV")[1])))
          Return
     EndIf
  EndIf        

  A097ProcLib(SCR->(Recno()),nOpc,SCR->CR_TOTAL,SCR->CR_APROV,SCR->CR_GRUPO,cObsBlq,dDataBase)    // Liberar / Bloquear documento

  // --- Mensagem no console
  // --- 1 - Liberou
  // --- 2 - Bloqueio PCO 
  // --- 3 - Rejeitado
  // -----------------------
   Do Case
      Case nOpc == 4                                    
           ConOut(" ==> Pedido de Compras Liberada  " + cNumSC7)
      
           cMsgSol := ", foi LIBERADO."
      
      Case nOpc == 7
           ConOut(" ==> Pedido de Compras Rejeitada " + cNumSC7)
      
           cMsgSol := ", foi REJEITADO."
   EndCase

   ConOut(" ==> WF DOCUMENTO ENTRADA (RETORNO de aprovação - Fim): " + cNumSC7)
 
  // --- Adicione informacao a serem incluidas na rastreabilidade
  // ------------------------------------------------------------
   cTexto    := "Finalizando o processo..."
   cCdStatus := "100205"                       
Return

//-----------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} fnW57Apv
  Constroi vetor com dados dos aprovadores do Docto de Entrada
  Passado como parametros

  parametros: cDocApv - Codigo do documento de entrada para
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
  history
  03/03/2021 - Desenvolvimento da Rotina.
/*/
Static Function fnW57Apv(pNumPC)
  Local aInfo      := {}
  Local aAprovador := {}
  Local cTpAprov   := ""

  dbSelectArea("SCR")
  SCR->(dbSetorder(1))
  
  If SCR->(dbSeek(FWxFilial("SCR") + "IP" + pNumPC))
     cTpAprov := "IP"

   elseIf SCR->(dbSeek(FWxFilial("SCR") + "PC" + pNumPC))
          cTpAprov := "PC"
  EndIf

 // --- Loop em documentacao p/alcada para verificar
 // --- quem deve aprovar a liberacao.
 // ------------------------------------------------
  While ! (SCR->(Eof())) .and. SCR->CR_FILIAL == FWxFilial("SCR") .and. AllTrim(SCR->CR_TIPO) == cTpAprov .and.;
        Alltrim(SCR->CR_NUM) == cNumPC
    dbSelectArea("SAL")
    SAL->(dbSetorder(3))
    SAL->(dbSeek(xFilial("SAL") + SCR->CR_GRUPO + SCR->CR_APROV))
	
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
