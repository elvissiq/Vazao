#Include "TOTVS.CH"

/*/{Protheus.doc} MA410MNU

Este ponto de entrada pode ser utilizado para inserir novas op��es no array aRotina.

@type function
@author TOTVS NORDESTE
@since 17/03/2023

@history 
/*/
User Function MA410MNU()

     If !IsBlind() 
        aAdd(aRotina,{'Gerar Solicitacoes','U_MYMATA650C',0,3,0,NIL})
        aAdd(aRotina,{'Imprimir Pedido','U_zRPedVen',0,3,0,NIL})
     EndIf 

Return 
