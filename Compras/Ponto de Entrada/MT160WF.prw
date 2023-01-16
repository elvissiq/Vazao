#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA161
  Fun��o MT160WF
  @par�metro N�o h�
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT160WF - Ponto de entrada ap�s a grava��o dos pedidos de compras pela analise da cota��o e
              antes dos eventos de contabiliza��o, utilizado para os processos de workFlow
              posiciona a tabela SC8 e passa como parametro o numero da cota��o.

  Return aRotina - rotina com a chamado do programa
  @historia
  21/03/2021 - Desenvolvimento da Rotina.
/*/
User Function MT160WF()
  Local aArea   := GetArea()
  Local cNumCot := ParamIxb[01]     // N�mero da Cota��o de Pre�o
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
