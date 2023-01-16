#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA130
  Fun��o MT131MNU
  @par�metro N� h�
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT131MNU - Ponto de entrada para inclus�o de rotina no browser da Cota��o
               de pre�o.

  Return aRotina - rotina com a chamado do programa
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
User Function MT131MNU()
  aAdd(aRotina, {"Reenviar E-Mail - Fornecedor","U_ACOMW056(3,Nil,SC8->C8_NUM)",0,4,0,.F.})
Return
