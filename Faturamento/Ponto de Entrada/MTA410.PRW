#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} User Function MTA410
    Ponto-de-Entrada: MTA410 - Valida��o de toda a tela no Pedido de Venda
    @type  MTA410
    @author TOTVS Nordeste
    @since 02/06/2023
    @version 1.0
    @see (https://tdn.totvs.com/pages/releaseview.action?pageId=6784388)
    /*/

User Function MTA410()
Local nPosValor := Ascan(aHeader, {|x| AllTrim(x[2]) == "C6_VALOR"})
Local nValTot   := 0
Local nId

    For nId:=1 to len(aCols)
        If !aCols[nId][Len(aHeader)+1]
            nValTot += aCols[nId,nPosValor]
        EndIf 
    Next nId

    M->C5_XTOTAL := nValTot

Return .T.
