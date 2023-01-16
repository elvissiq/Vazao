#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA131
  Fun��o MT131WF
  @par�metro N�o h�
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT131WF - Este ponto de entrada tem o objetivo de permitir a customiza��o de workflow
              baseado nas informa��es de cota��es que est�o sendo geradas pela rotina em
              execu��o.

  Return aRotina - rotina com a chamado do programa
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
User Function MT131WF()
  Local cNumCot := ParamIXB[1]        // N�mero da cota��o
  Local aRet2   := ParamIXB[2]
  Local aArea   := GetArea()

  U_ACOMW056(3,Nil,cNumCot)     // E-Mail para o(s) fornecedor(es) realizar a cota��o

  RestArea(aArea)
Return
