#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA161
  Função MT160WF
  @parâmetro Não hã¡
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT160WF - Ponto de entrada após a gravação dos pedidos de compras pela analise da cotação e
              antes dos eventos de contabilização, utilizado para os processos de workFlow
              posiciona a tabela SC8 e passa como parametro o numero da cotação.

  Return aRotina - rotina com a chamado do programa
  @historia
  21/03/2021 - Desenvolvimento da Rotina.
/*/
User Function MT160WF()
  Local aArea   := GetArea()
  Local cNumCot := ParamIxb[01]     // Número da Cotação de Preço
  Local cQuery  := ""

  cQuery := "Select Distinct SC8.C8_NUMPED from " + RetSqlName("SC8") + " SC8"
  cQuery += "  where SC8.D_E_L_E_T_ <> '*'"
  cQuery += "    and SC8.C8_FILIAL = '" + FWxFilial("SC8") + "'"
  cQuery += "    and SC8.C8_NUM    = '" + cNumCot + "'"
  cQuery += "    and SC8.C8_NUMPED <> 'XXXXXX'"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSC8",.F.,.T.)

  While ! QSC8->(Eof())
    U_ACOMW057(3,Nil,QSC8->C8_NUMPED)     // E-Mail para o(s) aprovador(es) do Pedido de Compras

    QSC8->(dbSkip())
  EndDo
  
  QSC8->(dbCloseArea())

  RestArea(aArea)
Return 
