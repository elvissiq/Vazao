#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} User Function SE5FI070
    Ponto-de-Entrada: SE5FI070 - Gravação de dados complementares da tabela SE5
    @type  SE5FI070
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 24/01/2023
    @version 1.0
    @see (https://tdn.totvs.com/pages/releaseview.action?pageId=146967645)
/*/

User Function SE5FI070()
Local cIDOrig   := ""
Local cIDTitulo := ""
Local cQry      := ""
Local nStatus   := -1

IF !Empty(SE1->E1_XPEDIDO)

    cIDOrig := SE5->E5_IDORIG

    cIDTitulo := SE1->E1_FILIAL+SE1->E1_PREFIXO+;
                    SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO

    //Update SE2 (Contas a Pagar)
    TCLink()
        cQry := " Update " + RetSqlName("SE2") 
        cQry += " Set E2_XIDTIT = '"+cIDOrig+"' "
        cQry += " Where " 
        cQry += " D_E_L_E_T_ <> '*' "
        cQry += " and E2_FILIAL = '"+FWxFilial("SE2")+"' "
        cQry += " and E2_XIDTIT = '"+cIDTitulo+"' "
            
        //Executando Update
        nStatus := TCSqlExec(cQry)
            
        If (nStatus < 0)
            FWAlertInfo("Houve um erro na tentativa do Update." + CRLF + TCSQLError(),;
                        "Update SE2")
        endif
    TCUnlink()

    nStatus := -1

    //Update SC5 (Pedido de Venda)
    TCLink()
        cQry := " Update " + RetSqlName("SC5") 
        cQry += " Set C5_XIDTIT = '"+cIDOrig+"' "
        cQry += " Where " 
        cQry += " D_E_L_E_T_ <> '*' "
        cQry += " and C5_FILIAL = '"+FWxFilial("SC5")+"' "
        cQry += " and C5_XIDTIT = '"+cIDTitulo+"' "
            
            //Executando Update
        nStatus := TCSqlExec(cQry)
            
        If (nStatus < 0)
            FWAlertInfo("Houve um erro na tentativa do Update." + CRLF + TCSQLError(),;
                        "Update SC5")
        EndIf
    TCUnlink()
    
EndIf    

Return
