#Include "PROTHEUS.CH"
#Include "TBICONN.CH"
#Include "TbiCode.ch"
#Include "TopConn.CH"
#Include "Ap5mail.ch"

/*/{protheusDoc.marcadores_ocultos} ACOMW058
  Função ACOMW058
  @parâmetro pNumPC - Número do Pedido de Compras

  @author Totvs Nordeste - Anderson Almeida

  @sample
 // ACOMW058 - Workflow para avisar o fornecedor ganhador
  Return
  @historia
  25/02/2021 - Desenvolvimento da Rotina.
/*/
User Function ACOMW058(pNumPC)
  Local cBarras := If(isSRVunix(),"/","\")
  
  Local oProcess

  oProcess := TWFProcess():New("000004","Informação Fornecedor")
  oProcess:NewTask("Inicio", cBarras + "workflow" + cBarras + "wfcotprvn.htm")

 // --- Posicionar no Pedido Compras
 // --------------------------------
  dbSelectArea("SC7")
  SC7->(dbSetOrder(1))

  If ! SC7->(dbSeek(FWxFilial("SC7") + pNumPC))
     ApMsgAlert("Pedido de Compras não encontrado.","Atenção")
     Return
  EndIf

 // --- Posicionar no Fornecedor
 // ----------------------------    
  dbSelectArea("SA2")
  SA2->(dbSetOrder(1))
  
  If ! SA2->(dbSeek(FWxFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA))
     ApMsgAlert("Fornecedor não cadastro do Pedido de Compras " + SC7->C7_FORNECE +;
                "/" + SC7->C7_LOJA,"Atenção")
     Return
  EndIf
     
  oProcess:oHtml:ValByName("A2_NOME"   , SA2->A2_NOME)
  oProcess:oHtml:ValByName("C7_FORNECE", SC7->C7_NUM)
  oProcess:oHtml:ValByName("C7_LOJA"   , SC7->C7_LOJA)
  oProcess:oHtml:ValByName("A2_END"    , SA2->A2_END)
  oProcess:oHtml:ValByName("A2_NR_END" , SA2->A2_NR_END)
  oProcess:oHtml:ValByName("A2_BAIRRO" , SA2->A2_BAIRRO)
  oProcess:oHtml:ValByName("A2_MUN"    , AllTrim(SA2->A2_MUN) + " / " + SA2->A2_EST)
  oProcess:oHtml:ValByName("A2_TEL"    , "(" + AllTrim(SA2->A2_DDD) + ")" + SA2->A2_TEL)
  oProcess:oHtml:ValByName("C7_NUM"    , SC7->C7_NUM)
  oProcess:oHtml:ValByName("Empresa"   , FWCompanyName())
  oProcess:oHtml:ValByName("Fone"      , "(87) 3848-2500")

  oProcess:ClientName("Administrador")
  
  oProcess:cTo      := SA2->A2_EMAIL
  oProcess:cSubject := "Alerta Aprovação Compras"

  oProcess:Start()
 
  oProcess:Free()
  oProcess:Finish()
  oProcess:= Nil

  WfSendMail()

  ApMsgInfo("Enviado E-Mail para o fornecedor " + SA2->A2_NREDUZ + ", com sucesso.")
Return
