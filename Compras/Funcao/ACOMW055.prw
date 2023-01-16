#Include "PROTHEUS.CH"
#Include "TBICONN.CH"
#Include "TbiCode.ch"
#Include "TopConn.CH"
#Include "Ap5mail.ch"

/*/{protheusDoc.marcadores_ocultos} ACOMW055
  Função ACOMW055
  @parâmetro pNumSC - Número da Solicitação de Compras

  @author Totvs Nordeste - Anderson Almeida

  @sample
 // ACOMW054 - Workflow Aprovação Solicitação de Compras
  Return
  @historia
  25/02/2021 - Desenvolvimento da Rotina.
/*/
User Function ACOMW055(nOpcao,oProcess,pNumSC)
  Local aArea := GetArea()

  Private cNumSC := ""

  If Empty(nOpcao)
     Default nOpcao := 0
     Default cNumSC := ""
  EndIf 

  If nOpcao == 3
     cNumSC := pNumSC
  EndIf 

  Do Case
     Case nOpcao == 0
          U_ApvSCIni()
          
     Case nOpcao == 3
          U_ApvSCIni()
          
     Case nOpcao == 1
          U_apvSCRet(oProcess)
          
     Case nOpcao == 2
          U_ApvSCTOut(oProcess)
  EndCase

  RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW055
  Função ApvSCIni

  @sample
 // ApvSCIni - Esta função é responsável por iniciar a criação do
               processo e por enviar a mensagem para o destinatário.
  Return
  @historia
  25/02/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function ApvSCIni()
  Local nCont    := 0
  Local cQuery   := ""
  Local aAprovSC := {}
  Local aDados   := {}

  
  If SC1->C1_APROV <> "B"
     //ApMsgAlert("Solicitação de Compras não encontra-se bloqueada.","ATENÇÃO")
     Return
  EndIf   
  
  
 // --- Pegar dados da Solicitação Compras
 // --------------------------------------
  cQuery := "Select SC1.C1_NUM, SC1.C1_SOLICIT, SC1.C1_EMISSAO, SC1.C1_NOMAPRO,"
  cQuery += "       SC1.C1_ITEM, SC1.C1_PRODUTO, SC1.C1_DESCRI, SC1.C1_QUANT,"
  cQuery += "       SC1.C1_UM, SC1.C1_DATPRF, SC1.C1_CC, SC1.C1_OBS"
  cQuery += "  from " + RetSqlName("SC1") + " SC1"
  cQuery += "   where SC1.D_E_L_E_T_ <> '*'"
  cQuery += "     and SC1.C1_FILIAL  = '" + FWxFilial("SC1") + "'"
  cQuery += "     and SC1.C1_NUM     = '" + cNumSC + "'"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSC1",.F.,.T.)
  
  While ! QSC1->(Eof())
    aAdd(aDados,{FWEmpName(cEmpAnt),;                    // 01 - Nome Empresa
                 QSC1->C1_NUM,;                          // 02 - Número da Solicitação de Compras
                 QSC1->C1_SOLICIT,;                      // 03 - Nome do solicitante
                 SToD(QSC1->C1_EMISSAO),;                // 04 - Emissão da Solicitação de Compras
                 QSC1->C1_NOMAPRO,;                      // 05 - Nome do Aprovador
                 QSC1->C1_ITEM,;                         // 06 - Item da Solicitação de Compras 
                 QSC1->C1_PRODUTO,;                      // 07 - Produto
                 QSC1->C1_DESCRI,;                       // 08 - Descrição do produto
                 QSC1->C1_QUANT,;                        // 09 - Quantidade do produto
                 QSC1->C1_UM,;                           // 10 - Unidade de medida do produto
                 SToD(QSC1->C1_DATPRF),;                 // 11 - Data da preferencial da entrega do produto
                 QSC1->C1_CC,;                           // 12 - Centro de Custo
                 QSC1->C1_OBS,;                          // 13 - Observação
                 FWFilialName()})                        // 14 - Nome da filial

    QSC1->(dbSkip())
  EndDo

  QSC1->(dbCloseArea())
  
  If Len(aDados) == 0
     ApMsgInfo("Solicitação de Compras não encontrada.")
   else
     aAprovSC := fnW55Apv(cNumSC)

     For nCont := 1 To Len(aAprovSC)
         fnW55Mail(aAprovSC[nCont], aDados)
     Next nCont
  EndIf   
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW055
  Função fnW55Mail

  @sample
 // fnW55Mail - Envia e-mail para os aprovadores. 

  Return
  @historia
  25/02/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
Static Function fnW55Mail(aEnvPara, aDados)
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

  cClickPara  := "Solicitação Compras"
  cCdStatus   := "100100"  
  cServWF     := GetMv("MV_XURLWF")
  cHtmlModelo := cBarras + "workflow" + cBarras + "aprovasc_reg.htm"
  cAssunto    := "Aprovação Solicitação Compras - " + cNumSC
 
  oProcess := TWFProcess():New("000001", cAssunto)
  oProcess:NewTask(cAssunto, cHtmlModelo)

  ConOut("(INICIO|APVPC)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

  cTexto    := "Iniciando o processo de " + cAssunto + " N: " + cNumSC
  cCdStatus := "100105"                         // Código do cadastro de status de processo
  cTexto    := "Gerando solicitação para envio..."
  cCdStatus := "100106"

  oProcess:oHtml:ValByName("cEmpresa" , aDados[01][01])
  oProcess:ohtml:ValByName("cFilial"  , aDados[01][14])
  oProcess:oHtml:ValByName("cNum"     , aDados[01][02])
  oProcess:oHtml:ValByName("cSolicit" , aDados[01][03]) 
  oProcess:oHtml:ValByName("cEmissao" , DToC(aDados[01][04]))
//  oProcess:oHtml:ValByName("cNomAprov", aDados[01][05])
  oProcess:oHtml:ValByName("cCodAprov", aEnvPara[02])

  For nId := 1 To Len(aDados)
      aAdd(oProcess:oHtml:ValByName("it.ITEM")   , aDados[nId][06])
      aAdd(oProcess:oHtml:ValByName("it.PRODUTO"), aDados[nId][07])
      aAdd(oProcess:oHtml:ValByName("it.DESCRI") , aDados[nId][08])
      aAdd(oProcess:oHtml:ValByName("it.QUANT")  , Transform(aDados[nId][09],"@E 999,999,999.99"))
      aAdd(oProcess:oHtml:ValByName("it.UM")     , aDados[nId][10])
      aAdd(oProcess:oHtml:ValByName("it.DATPRF") , DToC(aDados[nId][11]))
      aAdd(oProcess:oHtml:ValByName("it.CC")     , aDados[nId][12])
      aAdd(oProcess:oHtml:ValByName("it.OBS")    , aDados[nId][13])
  Next
  
  oProcess:cSubject := cAssunto
  oProcess:cTo      := "apvsc"
  oProcess:bReturn  := "U_ACOMW055(1)"

 // Informe o nome da função do tipo timeout que será executada se houver um timeout
 // ocorrido para esse processo. Neste exemplo, será executada 5 minutos após o envio
 // do e-mail para o destinatário. Caso queira-se aumentar ou diminuir o tempo, altere
 // os valores das variáveis: nDias, nHoras e nMinutos.
  oProcess:bTimeOut := {{"U_ACOMW055(2)", nDias, nHoras, nMinutos}}

  cMailID := oProcess:Start()

  cHtmlModelo := cBarras + "workflow" + cBarras + "aprovasc_msg.htm"

  oProcess:NewTask(cAssunto, cHtmlModelo)

  ConOut("(INICIO|WFLINK)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

  oProcess:cSubject := cAssunto
  oProcess:cTo      := aEnvPara[05]

  oProcess:ohtml:ValByName("cNomAprov", aDados[01][05])
  oProcess:ohtml:ValByName("cEmpresa" , aDados[01][01])
  oProcess:ohtml:ValByName("cFilial"  , aDados[01][14])
  oProcess:ohtml:ValByName("cNumero"  , aDados[01][02])
  oProcess:ohtml:ValByName("cNomeSol" , aDados[01][03])
  oProcess:ohtml:ValByName("cCdAprv"  , aEnvPara[02])

 // ---- Mensagem do Click aqui para ....
  oProcess:ohtml:ValByName("LinkExt",cClickPara)	         //-- Mensagem do Link de remessa para contacao
  oProcess:ohtml:ValByName("proc_link","http://" + cServWf + "apvsc/" + cMailID + ".htm")

 // ---- Adicione informacao a serem incluidas na rastreabilidade
  cTexto    := "Enviando solicitação..."
  cCdStatus := "100107"

  oProcess:Start()

  cTexto    := "Aguardando retorno..."
  cCdStatus := "100108"
  
  ApMsgAlert("E-Mail enviado com sucesso...","ATENÇÃO")
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW055
  Função ApvSCRet

  @sample
 // ApvSCRet - Esta função é executada no retorno da mensagem enviada
               pelo destinatário. O Workflow recria o processo em que
               parou anteriormente na funcao APVInicio e repassa a
               variável objeto oProcess por parâmetro.
  Return
  @historia
  23/02/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function ApvSCRet(oProcess)
  Local cOpc     := ""
  Local cObsBlq  := " "
  Local cNumSC1  := AllTrim(oProcess:oHtml:RetByName("cNum"))
  Local cCdStatus, cTexto

  Conout("(RETORNO)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID)

  cObsBlq := oProcess:oHtml:RetByName("cMOTIVO")

 // --- Opção para confimrar ou não a aprovação "cAPROV" por ser:
 // ---   L = Aprovado chama 'A097ProcLib', opção '2' 
 // ---   R = Rejeitado chama 'MaAlcDoc', opção '7'
 // ------------------------------------------------------------- 
  cOpc := oProcess:oHtml:RetByName("cAPROV") 

 // --- Posiciona-se no Registro de Liberacao do APROVADOR
 // ------------------------------------------------------
  dbSelectArea("SCR")
  SCR->(dbSetorder(3)) 			// Codigo do Aprovador
  SCR->(dbSeek(FWxFilial("SCR") + "SC" + PadR(cNumSC1,TamSX3("CR_NUM")[1]) +;
               PadR(AllTrim(oProcess:oHtml:RetByName("cCodAprov")),TamSX3("CR_APROV")[1])))

  If cOpc == "L"              
     A097ProcLib(SCR->(Recno()),2,SCR->CR_TOTAL,SCR->CR_APROV,SCR->CR_GRUPO,cObsBlq,dDataBase)    // Liberar
  else
     MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,,SCR->CR_APROV,,SCR->CR_GRUPO,,,,dDataBase,cObsBlq},dDataBase,7,,,,,,,"") // Bloquear documento
  EndIf

  // --- Mensagem no console
  // --- L - Liberou
  // --- R - Rejeitado
  // -----------------------
   Do Case
      Case cOpc == "L"                                    
           ConOut(" ==> Solicitacao de Compras Liberada  " + cNumSC1)
      
           cMsgSol := ", foi LIBERADO."
      
      Case cOpc == "R"
           ConOut(" ==> Solicitacao de Compras Rejeitada " + cNumSC1)
      
           cMsgSol := ", foi REJEITADO."
   EndCase

   ConOut(" ==> WF DOCUMENTO ENTRADA (RETORNO de aprovação - Fim): " + cNumSC1)
 
  // --- Adicione informacao a serem incluidas na rastreabilidade
  // ------------------------------------------------------------
   cTexto    := "Finalizando o processo..."
   cCdStatus := "200801"                       
Return

//-----------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} fnW54Apv
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
  25/02/2021 - Desenvolvimento da Rotina.
/*/
//-----------------------------------------------------------------------
Static Function fnW55Apv(cSolCom)
  Local aInfo      := {}
  Local aAprovador := {}

  dbSelectArea("SCR")
  SCR->(dbSetorder(1))
  SCR->(dbSeek(xFilial("SCR") + "SC" + cSolCom))

 // --- Loop em documentacao p/alcada para verificar
 // --- quem deve aprovar a liberacao.
 // ------------------------------------------------
  While ! (SCR->(Eof())) .and. SCR->CR_FILIAL == FWxFilial("SCR") .and. SCR->CR_TIPO == "SC" .and.;
        Alltrim(SCR->CR_NUM) == cSolCom
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
