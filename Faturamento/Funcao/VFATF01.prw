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
@SINCE 18/05/2023
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
 
    ADD OPTION aRotina TITLE "Gerar Parcelas" ACTION "U_ProcParc()" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar Pedido"  ACTION "MatA410(,,,,'A410Visual')" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Estorno"  ACTION "MatA410(,,,,'A410Visual')" OPERATION 1 ACCESS 0
 
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
  cQuery += "    and SZ1.Z1_FILIAL  = '" + SC5->C5_FILIAL + "'"
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

/*---------------------------------------------------------------------*
 | Func:  xEstorPac                                                    |
 | Desc:  Realiza estorno das parcelas, pedido e titulo gerados        |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/

User Function xEstorPac()

Local aRet     := {}
Local aOpcoes  := {}
Local cTitulo  := "Seleção de Parcelas"
Local _cAlias  := "TMP_"+StrTran(Time(),":","")
Local cRet     := ""
Local cPedido  := SC5->C5_NUM
Local nTamChv  := GetSx3Cache("Z1_TOKEN", 'X3_TAMANHO')
Local nId, nTotal

Private cToken := ""

BeginSql alias _cAlias
  column Z1_VENCTO as Date
  SELECT
    SZ1.Z1_SEQ,
    SZ1.Z1_VALOR,
    SZ1.Z1_TOKEN
  FROM
    %table:SZ1% SZ1
  WHERE
    SZ1.Z1_FILIAL  = %xfilial:SZ1% AND
    SZ1.Z1_PEDIDO  = %Exp:cPedido%
    SZ1.%notDel% 
EndSql

(_cAlias)->(DbGoTop())
Count To nTotal
(_cAlias)->(DbGoTop())

While!(_cAlias)->(EOF())
  aAdd(aOpcoes, {(_cAlias)->Z1_SEQ +" - "+ (_cAlias)->Z1_VALOR })
  //cRet := (_cAlias)->Z1_SEQ
  (_cAlias)->(DbSkip())
EndDo

	// Executa f_Opcoes para Selecionar ou Mostrar os Registros Selecionados
     IF f_Opcoes(    aRet        ,;    //Variavel de Retorno
                     cTitulo     ,;    //Titulo da Coluna com as opcoes
                     aOpcoes     ,;    //Opcoes de Escolha (Array de Opcoes)
                     cRet        ,;    //String de Opcoes para Retorno
                     NIL         ,;    //Nao Utilizado
                     NIL         ,;    //Nao Utilizado
                     .F.         ,;    //Se a Selecao sera de apenas 1 Elemento por vez
                     nTamChv     ,;    //Tamanho da Chave
                     nTotal      ,;    //No maximo de elementos na variavel de retorno
                     .F.         ,;    //Inclui Botoes para Selecao de Multiplos Itens
                     .F.         ,;    //Se as opcoes serao montadas a partir de ComboBox de Campo ( X3_CBOX )
                     NIL         ,;    //Qual o Campo para a Montagem do aOpcoes
                     .T.         ,;    //Nao Permite a Ordenacao
                     .T.         ,;    //Nao Permite a Pesquisa    
                     .T.         ,;    //Forca o Retorno Como Array
                     ""           ;    //Consulta F3
                )  
	EndIF

   For nId := 1 To Len(aRet)
        cToken := aRet[nId]
   Next nId 

(_cAlias)->(DbCloseArea())

Return
