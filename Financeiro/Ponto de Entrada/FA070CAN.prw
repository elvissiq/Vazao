#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} User Function FA070CAN
    Ponto-de-Entrada: F070CCAN -Validações adicionais
    @type  FA070CAN
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 23/01/2023
    @version 1.0
    @see (https://tdn.totvs.com/pages/releaseview.action?pageId=6071588)
/*/

User Function FA070CAN()

Local aArea     := GetArea()

Public cIDOrig := ""
Public _nOper  := 5

    If  SE1->E1_PREFIXO == "AGE" .And. SE1->E1_TIPO == "AGE" .And. !Empty(SE1->E1_XPEDIDO)
        
        cIDOrig := SE5->E5_IDORIG
        
        U_VFINF002()
        
    EndIf 

RestArea(aArea)

Return
