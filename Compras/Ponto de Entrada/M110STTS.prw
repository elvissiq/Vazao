#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA110
  Fun��o M110STTS
  @par�metro N� h�
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT110ROT -  Ap�s a grava��o da Solicita��o pela fun��o A110Grava em inclus�o, altera��o
                e exclus�o, localizado fora da transa��o possibilitando assim a inclus�o de
                interface ap�s a grava��o de todas as solicita��es.

  Return aRotina - rotina com a chamado do programa
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
User Function M110STTS()
  Local aArea   := GetArea()
  Local cNumSol := Paramixb[1]           // N�mero da Solicita��o
  Local nOpcao  := Paramixb[2]           // Opera��o: 1 = Inclus�o, 2 = Altera��o ou 3 = Exclus�o
// Local lCopia  := Paramixb[3]           // Se a Solicita��o de Compra � originada de uma c�pia

  If ! FunName() == "MATA185"
     If nOpcao < 3
        U_ACOMW055(3,Nil,cNumSol)
     EndIf
  EndIf

  RestArea(aArea)   
Return 
