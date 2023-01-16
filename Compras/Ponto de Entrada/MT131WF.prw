#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA131
  Função MT131WF
  @parâmetro Não hã
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT131WF - Este ponto de entrada tem o objetivo de permitir a customização de workflow
              baseado nas informações de cotações que estão sendo geradas pela rotina em
              execução.

  Return aRotina - rotina com a chamado do programa
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
User Function MT131WF()
  Local cNumCot := ParamIXB[1]        // Número da cotação
  Local aRet2   := ParamIXB[2]
  Local aArea   := GetArea()

  U_ACOMW056(3,Nil,cNumCot)     // E-Mail para o(s) fornecedor(es) realizar a cotação

  RestArea(aArea)
Return
