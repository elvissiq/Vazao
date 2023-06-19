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
@OWNER VAZAO  
@VERSION PROTHEUS 12
@SINCE 02/06/2023
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
 
    ADD OPTION aRotina TITLE "Gerar Comissao"     ACTION "U_ProcParc()" OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar Pedido"  ACTION "MatA410(,,,,'A410Visual')" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE 'Estorno'            ACTION "U_EstProc()" OPERATION 5 ACCESS 0
 
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

    oStruct:SetProperty("C5_XFABRIC", MVC_VIEW_ORDEM, "04")
    oStruct:SetProperty("C5_XLOJFAB", MVC_VIEW_ORDEM, "05")
    oStruct:SetProperty("C5_XNFABRI", MVC_VIEW_ORDEM, "06")
    oStruct:SetProperty("C5_XTOTAL" , MVC_VIEW_ORDEM, "07")
    oStruct:SetProperty("C5_EMISSAO", MVC_VIEW_ORDEM, "08")
    oStruct:SetProperty("C5_VEND1"  , MVC_VIEW_ORDEM, "09")
    oStruct:SetProperty("C5_XNOMEVD", MVC_VIEW_ORDEM, "10")

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
Private cUUID := FWUUID(FWTimeStamp(1))

  FWExecView("Pedido de Venda: "+SC5->C5_NUM,"VFATF02",MODEL_OPERATION_UPDATE,,{|| .T.},,,)

Return
 
/*---------------------------------------------------------------------*
 | Func:  EstProc()                                                    |
 | Desc:  Realiza Estorno do processo de Agenciamento                  |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
User Function EstProc()
Local aArea := GetArea()
Local _cAlias := "TMP_"+FWTimeStamp(1) 

Private lRet  := .T.
Private cUUID := ""

  If FWAlertYesNo('Deseja realmente realizar o Estorno da Comissão/Pedido (NFS) gerados para o Pedido: '+ SC5->C5_NUM+;
                  '. Este procedimento não poderá ser desfeito após clicar em "Sim".', "Estorno")

    BeginSql alias _cAlias
      SELECT *
      FROM
          %table:SZ1%
      WHERE
          Z1_FILIAL = %xfilial:SZ1% AND
          Z1_PEDIDO = %Exp:SC5->C5_NUM% AND
          %notDel% 
    EndSql

    While !(_cAlias)->(EOF())

      lRet := .T.
      cUUID := Alltrim((_cAlias)->Z1_UUID)
      
      If !Empty(cUUID)
        MsgRun("Realizando estorno da Comissão e do Pedido (NFS).","Aguarde...",{|| ExecExc() }) //Estorno do Título a Pagar + Pedido de Venda NFS
      EndIf 

      If lRet
        DbSelectArea('SZ1')
        SZ1->(DbSetOrder(1))
        SZ1->(DbGoTop())
        If SZ1->(MsSeek(xFilial('SZ1')+(_cAlias)->Z1_PEDIDO))
          RecLock('SZ1', .F.)
            DbDelete()
          SZ1->(MsUnlock())
        EndIf

        DbSelectArea('SZ2')
        SZ2->(DbSetOrder(1))
        SZ2->(DbGoTop())
        If SZ2->(MsSeek(xFilial('SZ2')+(_cAlias)->Z1_PEDIDO))
          While !SZ2->(EOF()) .And. ( SZ2->Z2_PEDIDO == (_cAlias)->Z1_PEDIDO )
            RecLock('SZ2', .F.)
              DbDelete()
            SZ2->(MsUnlock())
            SZ2->(DBSkip())
          EndDo 
        EndIf
      
      EndIf 
      (_cAlias)->(DBSkip())
    
    EndDo

    If Select(_cAlias) > 0                                 
      (_cAlias)->(dbCloseArea())
    EndIf  

  EndIf

RestArea( aArea ) 
Return

/*---------------------------------------------------------------------*
 | Func:  ExecExc()                                                    |
 | Desc:  Efetua o estorno do Título e/ou Pedido de Venda              |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
Static Function ExecExc()
Local aArea    := GetArea()
Local aVetSE2  := {}
Local aCabec   := {}
Local aItens   := {}
Local aLinha   := {}
Local _cAlias  := "TMP_"+FWTimeStamp(1)
Local _cAlias2 := "TMP2_"+FWTimeStamp(1)

BeginSql alias _cAlias
    SELECT
        E2_PREFIXO,
        E2_NUM,
        E2_PARCELA,
        E2_TIPO,
        E2_XUUID
    FROM
        %table:SE2%
    WHERE
        E2_FILIAL = %xfilial:SE2% AND
        E2_XUUID  = %Exp:cUUID% AND
        %notDel% 
        ORDER BY E2_NUM
EndSql

While!(_cAlias)->(EOF())
  
  DBSelectArea('SE2')
  SE2->(DBSetOrder(1))
  If SE2->(MSSeek(xFilial('SE2')+(_cAlias)->E2_PREFIXO+(_cAlias)->E2_NUM+(_cAlias)->E2_PARCELA+(_cAlias)->E2_TIPO))
    
    aVetSE2 := {}

    aAdd(aVetSE2, {"E2_PREFIXO", (_cAlias)->E2_PREFIXO, Nil})
    aAdd(aVetSE2, {"E2_NUM"    , (_cAlias)->E2_NUM,     Nil})

    Begin Transaction
      lMsErroAuto := .F.
      MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aVetSE2,, 5)
          
      If lMsErroAuto
        MostraErro()
        DisarmTransaction()
        lRet := .F.
      EndIf
    End Transaction
  EndIf 

(_cAlias)->(DBSkip())
EndDo 

If Select(_cAlias) > 0                                 
  (_cAlias)->(dbCloseArea())
EndIf

If !lRet
  Return
EndIf 

BeginSql alias _cAlias
    SELECT *
    FROM
        %table:SC5%
    WHERE
        C5_FILIAL = %xfilial:SC5% AND
        C5_XUUID  = %Exp:cUUID% AND
        %notDel% 
EndSql

While!(_cAlias)->(EOF())

  DBSelectArea('SC5')
  SC5->(DBSetOrder(1))
  If SC5->(MSSeek(xFilial('SE2')+(_cAlias)->C5_NUM))

      aadd(aCabec, {"C5_NUM"    , (_cAlias)->C5_NUM,     Nil})
      aadd(aCabec, {"C5_TIPO"   , (_cAlias)->C5_TIPO,    Nil})
      aadd(aCabec, {"C5_CLIENTE", (_cAlias)->C5_CLIENTE, Nil})
      aadd(aCabec, {"C5_LOJACLI", (_cAlias)->C5_LOJACLI, Nil})
      aadd(aCabec, {"C5_CONDPAG", (_cAlias)->C5_CONDPAG, Nil})

      BeginSql alias _cAlias2
          SELECT *
          FROM
              %table:SC6%
          WHERE
              C6_FILIAL = %xfilial:SC6% AND
              C6_NUM    = %Exp:(_cAlias)->C5_NUM% AND
              %notDel% 
      EndSql

        While!(_cAlias2)->(EOF())
          aLinha := {}
          aadd(aLinha,{"C6_ITEM",    (_cAlias2)->C6_ITEM,     Nil})
          aadd(aLinha,{"C6_PRODUTO", (_cAlias2)->C6_PRODUTO,  Nil})
          aadd(aLinha,{"C6_QTDVEN",  (_cAlias2)->C6_QTDVEN,   Nil})
          aadd(aLinha,{"C6_PRCVEN",  (_cAlias2)->C6_PRCVEN,   Nil})
          aadd(aLinha,{"C6_PRUNIT",  (_cAlias2)->C6_PRUNIT,   Nil})
          aadd(aLinha,{"C6_TES",     (_cAlias2)->C6_TES,      Nil})
          aadd(aItens, aLinha)
        (_cAlias2)->(DBSkip())
        EndDo 

      If Select(_cAlias2) > 0                                 
        (_cAlias2)->(dbCloseArea())
      EndIf

    Begin Transaction
      lMsErroAuto := .F.
      MSExecAuto({|a, b, c| MATA410(a, b, c)}, aCabec, aItens, 5)
          
      If lMsErroAuto
        MostraErro()
        DisarmTransaction()
        lRet := .F.
      EndIf
    End Transaction
  EndIf 

(_cAlias)->(DBSkip())
EndDo 

If Select(_cAlias) > 0
  (_cAlias)->(dbCloseArea())
EndIf

RestArea(aArea)

Return
