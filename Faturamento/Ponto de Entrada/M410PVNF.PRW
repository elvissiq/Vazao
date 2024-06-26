#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} User Function M410PVNF
    Ponto-de-Entrada: M410PVNF - Gera��o de notas fiscais
    Executado antes da rotina de gera��o de NF's (MA410PVNFS()).
    @return
    (logico)
      Variavel logica, sendo:
      .T. (prossegue o processamento para a gera��o da NF.)
      .F. (impede o processamento.)
    @example
    @see (https://tdn.totvs.com/pages/releaseview.action?pageId=6784152)
    /*/

User Function M410PVNF()
Local lRet := .T.

   If !Empty(C5_XFABRIC) .And. !Empty(C5_XLOJFAB)
      lRet := .F.
      FWAlertWarning("Pedido de venda do tipo agenciamento n�o deve ser faturado.",;
                     "Pedido Agenciamento")
   EndIf 

Return lRet
