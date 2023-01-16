#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA130
  Função MT131MNU
  @parâmetro Nã há
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT131MNU - Ponto de entrada para inclusão de rotina no browser da Cotação
               de preço.

  Return aRotina - rotina com a chamado do programa
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
User Function MT131MNU()
  aAdd(aRotina, {"Reenviar E-Mail - Fornecedor","U_ACOMW056(3,Nil,SC8->C8_NUM)",0,4,0,.F.})
Return
