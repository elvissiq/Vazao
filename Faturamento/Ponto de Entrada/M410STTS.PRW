#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} User Function M410STTS
    Este ponto de entrada pertence à rotina de pedidos de venda, MATA410().
    Está em todas as rotinas de inclusão, alteração, exclusão, cópia e devolução de compras.
    Executado após todas as alterações no arquivo de pedidos terem sido feitas
    @type  M410STTS
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 26/01/2023
    @version 1.0
    @param 
    nOper --> Tipo: Numérico - Descrição: Operação que está sendo executada, sendo:
        3 - Inclusão
        4 - Alteração
        5 - Exclusão
        6 - Cópia
        7 - Devolução de Compras
    @return 
    @example
    @see (https://tdn.totvs.com/pages/releaseview.action?pageId=6784155)
    /*/

User Function M410STTS()

Private _nOper  := PARAMIXB[1]

If _nOper == 7
   Return
EndIf 

   If !Empty(C5_XFABRIC) .And. !Empty(C5_XLOJFAB)
      
      //U_VFATF001() //Função para gerar Contas a Receber quando Pedido for Agenciamento.

   EndIf 

Return
