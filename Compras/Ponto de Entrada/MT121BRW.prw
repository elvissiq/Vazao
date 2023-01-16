#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA121
  Função MT121BRW
  @parâmetro Nã há
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT121BRW - Ponto de entrada no browser da rotina de Pedido de Compras para
               adicionar chamada de rotina no menu.

  Return aRotina - rotina com a chamado do programa
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
User Function MT121BRW()
  aAdd(aRotina, {"E-Mail Aprovador" ,"U_ACOMW057(3,Nil,SC7->C7_NUM)",0,4,0,.F.})
  aAdd(aRotina, {"E-Mail Fornecedor","U_ACOMW058(SC7->C7_NUM)"      ,0,4,0,.F.})
Return
