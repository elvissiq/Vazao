#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA110
  Função M110STTS
  @parâmetro Nã há
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT110ROT -  Após a gravação da Solicitação pela função A110Grava em inclusão, alteração
                e exclusão, localizado fora da transação possibilitando assim a inclusão de
                interface após a gravação de todas as solicitações.

  Return aRotina - rotina com a chamado do programa
  @historia
  02/03/2021 - Desenvolvimento da Rotina.
/*/
User Function M110STTS()
  Local aArea   := GetArea()
  Local cNumSol := Paramixb[1]           // Número da Solicitação
  Local nOpcao  := Paramixb[2]           // Operação: 1 = Inclusão, 2 = Alteração ou 3 = Exclusão
// Local lCopia  := Paramixb[3]           // Se a Solicitação de Compra é originada de uma cópia

  If ! FunName() == "MATA185"
     If nOpcao < 3
        U_ACOMW055(3,Nil,cNumSol)
     EndIf
  EndIf

  RestArea(aArea)   
Return 
