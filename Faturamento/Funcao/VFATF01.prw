//Bibliotecas
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "TBICONN.CH"
#Include "TopConn.ch"

//Variveis Estaticas
Static cTitulo := "Agenciamento de Pedidos"
Static cAlias  := "SC5"

//----------------------------------------------------------------------
/*/{PROTHEUS.DOC} VFATF01
FUNÇÃO VFATF01 - Tela para Gerar comissão dos pedidos de agenciamento
@OWNER PanCristal
@VERSION PROTHEUS 12
@SINCE 17/03/2023
@Tratamento para comissao de Pedidos do tipo agenciamento
/*/
//----------------------------------------------------------------------


User Function VFATF01()
Local aArea   := GetArea()
Local oBrowse

Private aRotina := {}

aRotina := MenuDef()

oBrowse := FWMBrowse():New()
oBrowse:SetAlias(cAlias)
oBrowse:SetDescription(cTitulo)
oBrowse:SetFilterDefault("C5_XFABRIC <> ''")

oBrowse:AddLegend("U_PStatus('N')", 'BR_BRANCO'   , 'Nenhuma Parcela Gerada')
oBrowse:AddLegend("U_PStatus('A')", 'BR_VERDE'    , 'Parcela Gerada sem Pagamento')
oBrowse:AddLegend("U_PStatus('F')", 'BR_VERMELHO' , 'Pagamento Finalizado')
oBrowse:AddLegend("U_PStatus('P')", 'BR_AZUL'     , 'Pagamento Parcial')

oBrowse:Activate()
 
RestArea(aArea)
Return

Static Function MenuDef()
    Local aRotina := {}
 
    ADD OPTION aRotina TITLE "Consultar Parcelas" ACTION "U_ProcParc()" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar Pedido"  ACTION "MatA410(,,,,'A410Visual')" OPERATION 1 ACCESS 0 
 
Return aRotina

/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Desc:  Criação do modelo de dados MVC                               |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function ModelDef()
    Local oStruct := FWFormStruct(1, cAlias)
    Local oModel
    Local bPre    := Nil
    Local bPos    := Nil
    Local bCommit := Nil
    Local bCancel := Nil
 
    oModel := MPFormModel():New("VFATF01", bPre, bPos, bCommit, bCancel)
    oModel:AddFields("SC5MASTER", /*cOwner*/, oStruct)
    oModel:SetDescription(cTitulo)
    oModel:GetModel("SC5MASTER"):SetDescription(cTitulo)
    oModel:SetPrimaryKey({})

Return oModel
 
/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Desc:  Criação da visão MVC                                         |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function ViewDef()
    Local oModel := FWLoadModel("VFATF01")
    Local oStruct := FWFormStruct(2, cAliasMVC)
    Local oView
 
    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SC5", oStruct, "SC5MASTER")
    oView:CreateHorizontalBox("TELA" , 100 )
    oView:SetOwnerView("VIEW_SC5", "TELA")
 
Return oView

/*---------------------------------------------------------------------*
 | Func:  PStatus                                                   |
 | Desc:  Pesquisa o status do Pedido Agenciamento                     |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/

User Function PStatus(pTipo)

  Local aArea   := GetArea()
  Local lRet    := .F.
  Local cQuery  := ""
  Local nTotQry := 0
  Local nCount  := 0
  
  cQuery := "Select SZ1.Z1_MARK From " + RetSqlName("SZ1") + " SZ1"
  cQuery += "  where SZ1.D_E_L_E_T_ <> '*'"
  cQuery += "    and SZ1.Z1_FILIAL  = '" + FWxFilial("SZ1") + "'"
  cQuery += "    and SZ1.Z1_PEDIDO  = '" + SC5->C5_NUM + "'"
  TCQuery cQuery New Alias "QSZ1"
  Count To nTotQry

  QSZ1->(DBGoTOP())

  If pTipo == 'N'  //Nenhuma parcela gerada na tebela SZ1
      If Empty(nTotQry)
        lRet := .T.
      EndIf 
  EndIf 

  While !QSZ1->(Eof()) 
    If pTipo == 'A'
        If QSZ1->Z1_MARK == "F"
            ++nCount
        EndIf 
      ElseIf pTipo <> 'A'
        If QSZ1->Z1_MARK == "T"
          ++nCount
        EndIf 
    EndIf 
    QSZ1->(DBSkip())
  EndDo

  If pTipo == 'A' .AND. nCount > 0  //Parcelas em Aberto
      If nCount == nTotQry
        lRet := .T.
      EndIf
    ElseIF pTipo == 'F' .AND. nCount > 0 //Parcelas Totalmente Pagas
      If nCount == nTotQry
        lRet := .T.
      EndIf 
    ElseIF pTipo == 'P' .AND. nCount > 0 //Parcelas Pagas Parcialmente
      If nCount < nTotQry
        lRet := .T.
      EndIf 
  EndIf 

  QSZ1->(dbCloseArea())

  RestArea(aArea)
Return lRet

/*---------------------------------------------------------------------*
 | Func:  ProcParc                                                     |
 | Desc:  Exibe parcelas do Pedido do tipo Agenciamento                |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/

User Function ProcParc()

  FWExecView("Pedido de Venda: "+SC5->C5_NUM,"VFATF02",MODEL_OPERATION_UPDATE,,{|| .T.},,,)

Return
