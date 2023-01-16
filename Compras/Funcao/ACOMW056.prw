#Include "Protheus.ch"
#Include "rwmake.ch"
#Include "TopConn.ch"
#Include "TbiConn.ch"
#Include "TbiCode.ch"
#Include "APWebSrv.ch"

/*/{protheusDoc.marcadores_ocultos} ACOMW056
  Fun��o ACOMW056
  @par�metro nOpcao - op��o de execu��o: 0 = Execu��o, 1 e 2 = Retorno
             oProcess - objeto do processo
             pCotacao - N�mero da cota��o de pre�o

  @author Totvs Nordeste - Anderson Almeida

  @sample
 // ACOMW056 - Workflow para envio de Cota��o de Pre�o
  Return
  @historia
  25/02/2021 - Desenvolvimento da Rotina.
/*/
User Function ACOMW056(nOpcao,oProcess,pCotacao)
  Private cNumCot := ""

  If Empty(nOpcao)
     Default nOpcao  := 0
     Default cNumCot := ""
  EndIf
  
  Do Case
	 Case nOpcao == 3
	      cNumCot := pCotacao

        U_CotCPIni()

	 Case nOpcao == 1
		    U_CotCPRet(oProcess)
		  
	 Case nOpcao == 2
		    U_CotCPOut(oProcess)
  EndCase
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW056
  Fun��o CotCPIni

  @sample
 // CotCPIni - Esta fun��o � respons�vel por iniciar a cria��o do
               processo e por enviar a mensagem para o destinat�rio.
  Return
  @historia
  27/02/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function CotCPIni()
  Local lEnviado  := .F.
  Local aInfo     := {}
  Local aCondPag  := {}
  Local cFornece  := Space(TamSX3("C8_FORNECE")[01])
  Local cLoja     := Space(TamSX3("C8_LOJA")[01])
  Local cEmail    := Space(30)
  Local cEmlFor   := ""
  Local cUsermail := UsrRetMail(__cUserID)
  Local cIPExter  := GetMv("MV_XURLWF")
  Local nDias     := 360
  Local nHoras    := 0
  Local nMinutos  := 0
  Local cHtmlMod  := ""
  Local cAssunto  := "Cota��o de Pre�o"
  Local cTexto    := "" 
  Local cQuery    := ""
  Local cBarras   := If(isSRVunix(),"/","\")

  Local cCdStatus, cMailID, cUser
  
  Private oProcess, oHtml

 // --- Condi��es Pagamentos
 // ------------------------
  cQuery := "Select SE4.E4_CODIGO, SE4.E4_DESCRI"
  cQuery += "  from " + RetSqlName("SE4") + " SE4"
  cQuery += "   where SE4.D_E_L_E_T_ <> '*'"
  cQuery += "     and SE4.E4_FILIAL  = '" + FWxFilial("SE4") + "'"
  cQuery += "     and SE4.E4_XFORNEC = 'S'"
  cQuery += "  Order by SE4.E4_CODIGO"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),"QSE4",.F.,.T.)

  while ! QSE4->(Eof())
    aAdd(aCondPag, QSE4->E4_CODIGO + "-" + AllTrim(QSE4->E4_DESCRI))

    QSE4->(dbSkip())
  EndDo

  QSE4->(dbCloseArea())

 // --- Pegar as cota��es
 // ---------------------
  cQuery := "Select Distinct SC8.C8_XWFCO, SC8.C8_FORNECE, SC8.C8_LOJA, SC8.C8_CONTATO,"
	cQuery += "       SA2.A2_NOME, SA2.A2_EMAIL, SA2.A2_CONTATO, SA2.R_E_C_N_O_ as RECNOSA2"
  cQuery += "  from " + RetSqlName("SC8") + " SC8, " + RetSqlName("SA2") + " SA2"
  cQuery += "   where SC8.D_E_L_E_T_ <> '*'"
  cQuery += "     and SC8.C8_FILIAL = '" + FWxFilial("SC8") + "'"
  cQuery += "     and SC8.C8_NUM    = '" + cNumCot + "'"
  cQuery += "     and SA2.D_E_L_E_T_ <> '*'"
  cQuery += "     and SA2.A2_FILIAL = '" + FWxFilial("SA2") + "'"
  cQuery += "     and SA2.A2_COD    = SC8.C8_FORNECE"
	cQuery += "     and SA2.A2_LOJA   = SC8.C8_LOJA"
  cQuery += "   order by SC8.C8_FORNECE, SC8.C8_LOJA"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),"QSC8",.F.,.T.)

  while ! QSC8->(Eof())
  	// --- Caso ja tenha sido respondida
    // ---------------------------------
	   If QSC8->C8_XWFCO == "1004"
	      QSC8->(dbSkip())
	      Loop
	   EndIf
	
   	 cFornece := QSC8->C8_FORNECE
	   cLoja    := QSC8->C8_LOJA
	   cEmlFor  := QSC8->A2_EMAIL
	
    // --- Caso n�o encontre um E-mail
    // -------------------------------
	   If Empty(cEmlFor)
	      If MsgYesNo("O Fornecedor - " + cFornece + " - " + cLoja +;
                    " n�o tem um E-Mail cadastrado, deseja cadastrar agora ?")
           Define MsDialog oDlg from 100,153 TO 329,435 Title "Endere�o de E-Mail" Pixel
		         @ 009,009 Say OemToAnsi("E-mail") Size 99,8 Of oDlg Pixel
		         @ 028,009 MsGet cEmail Size 79,10 Of oDlg Pixel
			
		         @ 062,039 BmpButton Type 1 Action Close(oDlg)
		      Activate MsDialog oDlg Centered

          dbSelectArea("SA2")
          SA2->(dbGoto(QSC8->RECNOSA2))

		      RecLock("SA2",.F.)
		        Replace SA2->A2_EMAIL with cEmail
		      SA2->(MsUnlock())                  
		 
		      cEmlFor := cEmail
	      EndIf
	   EndIf
	  // ----------------------------------------

	   If AllTrim(cEmlFor) <> ""
        cTexto    := "Iniciando a solicita��o de " + cAssunto + " N:" + cNumCot
        cCdStatus := "100001"  // C�digo do cadastro de status de processo
        cTexto    := "Gerando Cota��o de Pre�o para envio..."
        cCdStatus := "100002"
        cHtmlMod  := cBarras + "workflow" + cBarras + "cotpreco_reg.htm"
        cAssunto  := "Cota��o de Pre�o"
   
        oProcess := TWFProcess():New("000001", cAssunto)
        oProcess:NewTask(cAssunto, cHtmlMod)
	      oHtml    := oProcess:oHTML
       
        ConOut("(INICIO|000001)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

	     // --- Armazena dados do usuario
       // -----------------------------
	      PswOrder(1)
		
	      If PswSeek(cUsuario,.T.)
	         aInfo := PswRet(1)
	         cUser := aInfo[1,2]
	      EndIf
		
	     // --- Preenche os dados do cabe�alho
       // ----------------------------------
        oHtml:ValByName("cFilial"   , FWFilialName())
	      oHtml:ValByName("C8_NUM"    , cNumCot)
   	    oHtml:ValByName("A2_NOME"   , QSC8->A2_NOME)
	      oHtml:ValByName("C8_FORNECE", QSC8->C8_FORNECE)
	      oHtml:ValByName("C8_LOJA"   , QSC8->C8_LOJA)
    	  oHtml:ValByName("C8_CONTATO", QSC8->C8_CONTATO)
        oHtml:ValByName("c8_filent" , AllTrim(SM0->M0_ENDENT) + " - " +;
                                      AllTrim(SM0->M0_CIDENT) + " / " +;
                                      AllTrim(SM0->M0_ESTENT))
      
        dbSelectArea("SC8")
        SC8->(dbSetOrder(1))
        SC8->(dbSeek(FWxFilial("SC8") + cNumCot + cFornece + cLoja))
		
	     // --- Busca os itens
       // ------------------
	      While ! SC8->(Eof()) .and. SC8->C8_FILIAL == FWxFilial("SC8") .and. SC8->C8_NUM == cNumCot .and.;
           SC8->C8_FORNECE == cFornece .and. SC8->C8_LOJA == cLoja
	         aAdd((oHtml:ValByName("it.item"))      , SC8->C8_ITEM)
	         aAdd((oHtml:ValByName("it.produto"))   , SC8->C8_PRODUTO)
	         aAdd((oHtml:ValByName("it.descricao")) , Posicione("SB1",1,FWxFilial("SB1") + SC8->C8_PRODUTO,"B1_DESC"))
           aAdd((oHtml:ValByName("it.um"))        , SC8->C8_UM)
	         aAdd((oHtml:ValByName("it.quant"))     , Transform(SC8->C8_QUANT,"@E 99,999.99"))
           aAdd((oHtml:ValByName("it.preco"))     , Transform(0.00,"@E 999,999.99"))
           aAdd((oHtml:ValByName("it.icms"))      , Transform(0.00,"@E 999,999.99"))
           aAdd((oHtml:ValByName("it.ipi"))       , Transform(0.00,"@E 999,999.99"))
           aAdd((oHtml:ValByName("it.icmsst"))    , Transform(0.00,"@E 999,999.99"))
           aAdd((oHtml:ValByName("it.valor"))     , Transform(0.00,"@E 999,999.99"))
           aAdd((oHtml:ValByName("it.entrega"))   , "0")
		  
    		   RecLock("SC8")
		         Replace SC8->C8_XWFCO with "1003"
             Replace SC8->C8_XWFDT with dDataBase
			
		         If Empty(SC8->C8_XWFEMAIL)
		            If cUsername == "Administrador"
		               Replace SC8->C8_XWFEMAIL with GetMV("MV_RELACNT")
			           else
			             Replace SC8->C8_XWFEMAIL with cUsermail
			          EndIF
		         EndIf
			
		         Replace SC8->C8_XWFID with oProcess:fProcessID
		       SC8->(MsUnlock())
		  
		       SC8->(dbSkip())
	      EndDo

	      oHtml:ValByName("CondPag", aCondPag)
	      oHtml:ValByName("Frete"  , {"CIF","FOB"})
	      oHtml:ValByName("subtot" , Transform(0,"@E 999,999.99"))
	      oHtml:ValByName("vldesc" , Transform(0,"@E 999,999.99"))
	      oHtml:ValByName("valfre" , Transform(0,"@E 999,999.99"))
	      oHtml:ValByName("totped" , Transform(0,"@E 999,999.99"))

	      oProcess:cSubject := "Processo de gera��o de Cota��o de Pre�os - " + cNumCot
	      oProcess:cTo      := "cotpr"
	      oProcess:bReturn  := "U_ACOMW056(1)"
		            
       // Informe o nome da fun��o do tipo timeout que ser� executada se houver um timeout
       // ocorrido para esse processo. Neste exemplo, ser� executada 5 minutos ap�s o envio
       // do e-mail para o destinat�rio. Caso queira-se aumentar ou diminuir o tempo, altere
       // os valores das vari�veis: nDias, nHoras e nMinutos.
        oProcess:bTimeOut := {{"U_ACOMW056(2)", nDias, nHoras, nMinutos}}

        cMailID  := oProcess:Start()
        cHtmlMod := cBarras + "workflow" + cBarras + "cotpreco_msg.htm"

        oProcess:NewTask(cAssunto, cHtmlMod)

        ConOut("(INICIO|WFLINK)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

        oProcess:cSubject := cAssunto
	      oProcess:cTo      := cEmlFor

        oProcess:ohtml:ValByName("cEmpresa"  , FWEmpName(cEmpAnt))
        oProcess:ohtml:ValByName("WNomeTo"   , QSC8->A2_NOME)                                            
        oProcess:ohtml:ValByName("WContatoTo", QSC8->A2_CONTATO)
        oProcess:ohtml:ValByName("WEmailTo"  , cEmlFor)
        oProcess:ohtml:ValByName("WNomeFrom" , UsrFullName(__cUserId))
        oProcess:ohtml:ValByName("WEmailFrom", UsrRetMail(__cUserID))                  	
        oProcess:ohtml:ValByName("WTipDoc"   , "Cota��o Pre�o")
        oProcess:ohtml:valByName("WNrDoc"    , cNumCot)
        oProcess:ohtml:valByName("WClickPara","realizar Cota��o de Pre�o")

       oProcess:ohtml:ValByName("proc_link","http://" + cIPExter + "cotpr/" + cMailID + ".htm")
       
       cTexto    := "Enviando Cota��o de Pre�o..."
       cCdStatus := "100003"

       oProcess:Start()

       cTexto    := "Aguardando retorno..."
       cCdStatus := "100004"
       lEnviado  := .T.
	   else
	    // --- Atualizar SC8 para nao processar novamente
      // ----------------------------------------------
        dbSelectArea("SC8")
        SC8->(dbSetOrder(1))
        SC8->(dbSeek(FWxFilial("SC8") + cNumCot + cFornece + cLoja))
		
	     // --- Busca os itens
       // ------------------
	      While ! SC8->(Eof()) .and. SC8->C8_FILIAL == FWxFilial("SC8") .and. SC8->C8_NUM == cNumCot .and.;
           SC8->C8_FORNECE == cFornece .and. SC8->C8_LOJA == cLoja

   		     RecLock("SC8",.F.)
		         Replace SC8->C8_XWFID with "WF9999"
		       SC8->(MsUnlock())

           SC8->(dbSkip())
        EndDo   
	  EndIf
  
    QSC8->(dbSkip())
  EndDo

  QSC8->(dbCloseArea())

  If lEnviado
     ApMsgInfo("E-Mail de Cota��o enviado com sucesso.")
  EndIf
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW056
  Fun��o CotCPRet

  @sample
 // CotCPRet - Faz a gravacao no retorno do workflow.
  Return
  @historia
  28/02/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function CotCPRet(oProcess)
  Local nId      := 0
  Local nQtde    := 0
  Local nQtTot   := 0
  Local nPerQtde := 0
  Local nPerICMS := 0
  Local nPerIPI  := 0
  Local nVlDesc  := 0
  Local nValFre  := 0
  Local nValIPI  := 0
  Local nValICMS := 0
  Local nTtDesc  := 0
  Local nTtFrete := 0
  Local cQuery   := ""

  Private cNumCot  := Space(TamSX3("C8_NUM")[01])
  Private cFornece := Space(TamSX3("C8_FORNECE")[01])
  Private cLoja    := Space(TamSx3("C8_LOJA")[01]) 
       
  Conout("(RETORNO)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID)                   

  cNumCot  := oProcess:oHtml:RetByName("C8_NUM")
  cFornece := oProcess:oHtml:RetByName("C8_FORNECE")
  cLoja    := oProcess:oHtml:RetByName("C8_LOJA")
  nTtDesc  := Val(StrTran(StrTran(oProcess:oHtml:RetByName("VLDESC"),".",""),",","."))
  nTtFrete := Val(StrTran(StrTran(oProcess:oHtml:RetByName("VALFRE"),".",""),",","."))

  cQuery := "Select Sum(C8_QUANT) as QTDE from " + RetSqlName("SC8") 
  cQuery += "   where D_E_L_E_T_ <> '*'"
  cQuery += "     and C8_FILIAL  = '" + FWxFilial("SC8") + "'"
  cQuery += "     and C8_NUM     = '" + PadR(cNumCot,TamSX3("C8_NUM")[1]) + "'"
  cQuery += "     and C8_FORNECE = '" + cFornece + "'"
  cQuery += "     and C8_LOJA    = '" + cLoja + "'"
  cQuery += "  Group by C8_NUM, C8_FORNECE, C8_LOJA"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),"QSC8",.F.,.T.)

  If ! QSC8->(Eof())
     nQtTot := QSC8->QTDE
  EndIf

  QSC8->(dbCloseArea())

 // --- Grava Cota��o - SC8
 // -----------------------
  For nId := 1 To Len(oProcess:oHtml:RetByName("it.preco"))
	    cItem := StrZero(nId,4)
	   
	    dbSelectArea("SC8")
	    SC8->(dbSetOrder(1))
	    SC8->(dbSeek(FWxFilial("SC8") + PadR(cNumCot,TamSX3("C8_NUM")[1]) +;
                   Padr(cFornece,TamSX3("C8_FORNECE")[1]) +;
                   PadR(cLoja,TamSX3("C8_LOJA")[1]) + cItem))
	   
	    cIcm := SC8->C8_PICM

	   // --- Caso o prazo tenha vencido n�o permite grava��o
     // ---------------------------------------------------
	    If SC8->C8_XWFID == "9999"
	       Return
	    EndIf
	   // ---------------------------

      nValFre  := 0
      nVlDesc  := 0
      nPerICMS := Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.icms")[nId],".",""),",","."))
      nPerIPI  := Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.ipi")[nId],".",""),",","."))
      nValIPI  := (Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.valor")[nId],".",""),",",".")) * nPerIPI;
                   ) / 100
      nValICMS := (Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.valor")[nId],".",""),",",".")) * nPerIcms;
                   ) / 100
  
      If oProcess:oHtml:RetByName("Frete") <> "FOB"
         nQtde    := Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.quant")[nId],".",""),",","."))
         nPerQtde := (nQtde * 100) / nQtTot 
         nValFre  := (nTtFrete * nPerQtde) / 100
       else
         nValFre  := 0  
      EndIf

      If nTtDesc > 0
         nQtde    := Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.quant")[nId],".",""),",","."))
         nPerQtde := (nQtde * 100) / nQtTot 
         nVlDesc  := (nTtDesc * nPerQtde) / 100
      EndIf   
        
	    RecLock("SC8",.F.)
	      Replace SC8->C8_XWFCO   with "1004"
		    Replace SC8->C8_PRECO   with Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.preco")[nId],".",""),",","."))
      	Replace SC8->C8_TOTAL   with Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.valor")[nId],".",""),",","."))
        Replace SC8->C8_TPFRETE with Substr(oProcess:oHtml:RetByName("Frete"),1,1)
        Replace SC8->C8_VALFRE  with nValFre
		    Replace SC8->C8_VLDESC  with nVlDesc
        Replace SC8->C8_PICM    with nPerICMS
        Replace SC8->C8_BASEICM with Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.valor")[nId],".",""),",","."))
        Replace SC8->C8_VALICM  with nValICMS
        Replace SC8->C8_BASEIPI with Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.valor")[nId],".",""),",","."))
        Replace SC8->C8_ALIIPI  with nPerIPI
        Replace SC8->C8_VALIPI  with nValIPI
        Replace SC8->C8_VALSOL  with Val(StrTran(StrTran(oProcess:oHtml:RetByName("it.icmsst")[nId],".",""),",","."))
		    Replace SC8->C8_COND    with Substr(oProcess:oHtml:RetByName("CondPag"),1,3)
        Replace SC8->C8_PRAZO   with Val(oProcess:oHtml:RetByName("it.entrega")[nId])
        Replace SC8->C8_OBS     with AllTrim(oProcess:oHtml:RetByName("C8_OBS"))
      SC8->(MsUnlock())
  Next                 
Return

//-------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} ACOMW056
  Fun��o CotCPOut

  @sample
 // CotCPOut - APTimeOut - Esta fun��o ser� executada a partir do
               Scheduler no tempo estipulado pela propriedade
               :bTimeout da classe TWFProcess. Caso o processo tenha
               sido respondido em tempo h�bil, essa execu��o ser�
               descartada automaticamente.
  Return
  @historia
  01/03/2021 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------------------------------
User Function CotCPOut(oProcess)
  Local cCdStatus, cHtmlMod
  Local cNumCot, cTexto, cTitulo

  cHtmlMod := "\workflow\wferrolink.htm"
  cTitulo  := "Atualiza��o do pre�o de venda"

 // --- Adicione informa��o a serem incluidas na rastreabilidade
 // ------------------------------------------------------------
  cTexto    := "Executando TIMEOUT..."
  cCdStatus := "100006"

  oProcess:Track(cCdStatus, cTexto, "Administrador")  // Rastreabilidade

  cNumCot := oProcess:oHtml:RetByName("C8_NUM")

  oProcess:Finish()
Return
