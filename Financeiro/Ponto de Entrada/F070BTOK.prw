#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} User Function F070BTOK
    O ponto de entrada F070BTOK ser� habilitado na confirma��o da baixa a receber.
    Esse RdMake efetua valida��es com rela��o a baixa a receber, retorna .T. para aprovar a baixa ou .F. para reprovar e voltar para a tela com o titulo que ser� baixado.
    N�o devem se alterar os valores das variaveis PRIVATE pois os valores da baixa nao serao recalculados nesse momento.
    @type  F070BTOK
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 17/01/2023
    @version 1.0
    @return 
    lRet(logico)
    .T. - para aprovar a baixa - .F. - para reprovar e voltar para a tela com o t�tulo a ser baixado.
    @see (https://tdn.totvs.com/pages/releaseview.action?pageId=6070915)
    /*/

User Function F070BTOK()

Public lRet   := .F.
Public _nOper := 3

If  SE1->E1_PREFIXO == "AGE" .And. SE1->E1_TIPO == "AGE" .And. !Empty(SE1->E1_XPEDIDO)
    If FWAlertYesNo("Deseja gerar comiss�o para os vendedores associados ao Pedido de Venda origem deste t�tulo?",;
                    "T�tulo do tipo Agenciamento!")
        
        If U_VFINF001()
           lRet := .T. 
        EndIF 
    
    EndIf 
 else 
  
  lRet := .T. 

EndIf 

Return lRet
