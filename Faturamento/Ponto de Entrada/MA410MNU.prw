#Include "TOTVS.CH"

/*/{Protheus.doc} MA410MNU

Rotina Principal do Acelerador do Relatório do Pedido de Venda

@type function
@author TOTVS NORDESTE
@since 12/02/2019

@history 
/*/
User Function MA410MNU()
	  If !IsBlind() 
               aAdd(aRotina,{'Imprimir Pedido','U_zRPedVen',0,3,0,NIL})
     EndIf 

Return Nil 
