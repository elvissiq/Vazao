//Bibliotecas
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "TBICONN.CH"
#Include "TopConn.ch"

Static aFieldsSC5 := {"C5_NUM","C5_CLIENTE","C5_LOJACLI","C5_XNOME","C5_EMISSAO","C5_XFABRIC","C5_XLOJFAB","C5_XNFABRI"}

//----------------------------------------------------------------------
/*/{PROTHEUS.DOC} VFATF02
FUNÇÃO VFATF02 - Tela para Gerar comissão dos pedidos de agenciamento
@OWNER PanCristal
@VERSION PROTHEUS 12
@SINCE 18/05/2023
@Tratamento para comissao de Pedidos do tipo agenciamento
/*/
//----------------------------------------------------------------------


User Function VFATF02()
Local aArea    := GetArea()

RestArea(aArea)
Return
 
/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Desc:  Criação do modelo de dados MVC                               |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function ModelDef()
Local oModel
Local oStructSC5 := fnM01SC5()
Local oStructSZ1 := FWFormStruct(1, 'SZ1')
Local oStructSZ2 := FWFormStruct(1, 'SZ2')
Local bLinePre   := {|oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue| linePreGrid(oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue)}
Local bPost      := {|| FWProcess() }

    //Criando o modelo e os relacionamentos
    oModel := MPFormModel():New('VFATF02M',/*bPre*/,bPost,/*bCommit*/,/*bCancel*/)
    oModel:AddFields('SC5MASTER',/*cOwner*/,oStructSC5)
	  oModel:AddGrid('SZ1DETAIL','SC5MASTER',oStructSZ1,bLinePre,/*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
    oModel:AddGrid('SZ2DETAIL','SC5MASTER',oStructSZ2,/*bLinePre*/,/*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
    
    oModel:SetRelation('SZ1DETAIL',{{'Z1_FILIAL','FWxFilial("SZ1")'},;
                                    {'Z1_PEDIDO','C5_NUM'          };
                                   }, SZ1->(IndexKey(1)))

    oModel:SetRelation('SZ2DETAIL',{{'Z2_FILIAL','FWxFilial("SZ2")'},;
                                    {'Z2_PEDIDO','C5_NUM'          };
                                   }, SZ2->(IndexKey(1)))

	  oModel:SetPrimaryKey({})

    //oStructSZ1:SetProperty("Z1_MARK", MODEL_FIELD_WHEN, {||IIF(FWFldGet("Z1_MARK"),.F.,.T.)})
    oStructSZ1:AddTrigger("Z1_MARK" ,"Z1_DTPAG" ,{||.T.},{||IIF(Empty(FWFldGet("Z1_DTPAG")),dDataBase,CToD("  /  /    "))})

    oModel:GetModel('SZ1DETAIL'):SetOptional(.T.)
    oModel:GetModel('SZ2DETAIL'):SetOptional(.T.)

    oModel:SetDescription("Agenciamento")
    oModel:GetModel('SC5MASTER'):SetDescription('Dados do Pedido de Venda')
    oModel:GetModel('SZ1DETAIL'):SetDescription('Parcelas')
    oModel:GetModel('SZ2DETAIL'):SetDescription('Vendedores')
    
Return oModel
 
/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Desc:  Criação da visão MVC                                         |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function ViewDef()
Local oView 
Local oModel     := FWLoadModel('VFATF02')
Local oStructSC5 := fnV01SC5()
Local oStructSZ1 := FWFormStruct(2, 'SZ1')
Local oStructSZ2 := FWFormStruct(2, 'SZ2')   

    //Criando a View
    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:SetProgressBar(.T.)

    //Adicionando os campos do cabeçalho e o grid dos filhos
    oView:AddField('VIEW_SC5',oStructSC5,'SC5MASTER')
    oView:AddGrid('VIEW_SZ1', oStructSZ1,'SZ1DETAIL')
    oView:AddGrid('VIEW_SZ2', oStructSZ2,'SZ2DETAIL')

    oView:SetAfterViewActivate({|oView| ViewActv(oView)})
     
    //Setando o dimensionamento de tamanho
    oView:CreateHorizontalBox('CABEC',30)
    oView:CreateHorizontalBox("GRID" ,70)
    oView:CreateVerticalBox('GRIDSZ1',50,"GRID")
    oView:CreateVerticalBox('GRIDSZ2',50,"GRID")
     
    //Amarrando a view com as box
    oView:SetOwnerView('VIEW_SC5','CABEC')
    oView:SetOwnerView('VIEW_SZ1','GRIDSZ1')
    oView:SetOwnerView('VIEW_SZ2','GRIDSZ2')

    //Tratativa padrão para fechar a tela
    oView:SetCloseOnOk({||.T.})

    //Habilitando título
    oView:EnableTitleView('VIEW_SC5','Dados do Pedido de Venda')
    oView:EnableTitleView('VIEW_SZ1','Parcelas')
    oView:EnableTitleView('VIEW_SZ2','Vendedores')

    oView:SetNoDeleteLine('VIEW_SZ1')
    oView:SetNoDeleteLine('VIEW_SZ2')

Return oView

//-----------------------------------------
/*/ fnM01SC5
  Estrutura do Pedido de Venda
/*/
//-----------------------------------------
Static Function fnM01SC5()
Local oStruct    := FWFormModelStruct():New()
Local nId 

  oStruct:AddTable("SC5",aFieldsSC5,"Pedido de Venda")

  For nId := 1 To Len(aFieldsSC5)                                                                          
      oStruct:AddField(GetSx3Cache(aFieldsSC5[nId], 'X3_TITULO');
                      ,GetSx3Cache(aFieldsSC5[nId], 'X3_TITULO');
                      ,aFieldsSC5[nId];
                      ,GetSx3Cache(aFieldsSC5[nId], 'X3_TIPO'   );
                      ,GetSx3Cache(aFieldsSC5[nId], 'X3_TAMANHO');
                      ,GetSx3Cache(aFieldsSC5[nId], 'X3_DECIMAL'),Nil,Nil,{},.F.,,.F.,.F.,.F.)
  Next nId 

Return oStruct

//-------------------------------------------------------------------
/*/ Função fnV01SC5()
  Estrutura do grid SC5 (View)	
/*/
//-------------------------------------------------------------------
Static Function fnV01SC5()
Local oViewSC5   := FWFormViewStruct():New() 
Local nId 

  For nId := 1 To Len(aFieldsSC5) 
      oViewSC5:AddField(aFieldsSC5[nId],;                            // 01 = Nome do Campo
                        StrZero(nId,2),;                             // 02 = Ordem
                        GetSx3Cache(aFieldsSC5[nId], 'X3_TITULO'),;  // 03 = Título do campo
                        GetSx3Cache(aFieldsSC5[nId], 'X3_DESCRIC'),; // 04 = Descrição do campo
                        Nil,;                                        // 05 = Array com Help
                        GetSx3Cache(aFieldsSC5[nId], 'X3_TIPO'),;    // 06 = Tipo do campo
                        GetSx3Cache(aFieldsSC5[nId], 'X3_PICTURE'),; // 07 = Picture
                        Nil,;                                        // 08 = Bloco de PictTre Var
                        Nil,;                                        // 09 = Consulta F3
                        .F.,;                                        // 10 = Indica se o campo é alterável
                        Nil,;                                        // 11 = Pasta do Campo
                        Nil,;                                        // 12 = Agrupamnento do campo
                        Nil,;                                        // 13 = Lista de valores permitido do campo (Combo)
                        Nil,;                                        // 14 = Tamanho máximo da opção do combo
                        Nil,;                                        // 15 = Inicializador de Browse
                        .F.,;                                        // 16 = Indica se o campo é virtual (.T. ou .F.)
                        Nil,;                                        // 17 = Picture Variavel
                        Nil)                                         // 18 = Indica pulo de linha após o campo (.T. ou .F.)
  NExt nId
  
Return oViewSC5

/*---------------------------------------------------------------------*
 | Func:  ViewActv                                                     |
 | Desc:  Realiza o PUT nos campos para gravação na tabela SE1         |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
Static Function ViewActv(oView)
Local oModel := FWModelActive() 
Local oModelSC5 := oModel:GetModel("SC5MASTER")
Local oModelSZ1 := oModel:GetModel("SZ1DETAIL")
Local oModelSZ2 := oModel:GetModel("SZ2DETAIL")
Local cNomeCli  := Posicione("SA1",1,FWxFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")
Local nTotalPed := zTotPed(SC5->C5_NUM)
Local aParcelas := Condicao(nTotalPed,SC5->C5_CONDPAG,0,SC5->C5_EMISSAO,0) //Condicao(nValTot,cCond,nVIPI,dData,nVSol)
Local cCodVend  := ""
Local cNomVend  := ""
Local nPComis   := 0
Local nY 

  DBSelectArea("SC5")
  SC5->(DBSetOrder(1))
  If SC5->(MsSeek(xFilial("SC5")+SC5->C5_NUM))
        oModelSC5:SetValue("C5_NUM"     , SC5->C5_NUM    )
        oModelSC5:SetValue("C5_CLIENTE" , SC5->C5_CLIENTE)
        oModelSC5:SetValue("C5_LOJACLI" , SC5->C5_LOJACLI)
        oModelSC5:SetValue("C5_XNOME"   , cNomeCli       )
        oModelSC5:SetValue("C5_EMISSAO" , SC5->C5_EMISSAO)
        oModelSC5:SetValue("C5_XFABRIC" , SC5->C5_XFABRIC)
        oModelSC5:SetValue("C5_XLOJFAB" , SC5->C5_XLOJFAB)
        oModelSC5:SetValue("C5_XNFABRI" , SC5->C5_XNFABRI)
        oView:Refresh('VIEW_SC5')
  EndIf

  For nY := 1 To Len(aParcelas)
      DBSelectArea("SZ1")
      SZ1->(DBSetOrder(2))
      If !SZ1->(DBSeek(FWxFilial("SZ1")+SC5->C5_NUM+SC5->C5_CONDPAG+StrZero(nY,3)))
          
          If nY > 1 
            oModelSZ1:AddLine()
          EndIf 

          oModelSZ1:SetValue("Z1_MARK"    , .F.)
          oModelSZ1:SetValue("Z1_SEQ"     , StrZero(nY,3))
          oModelSZ1:SetValue("Z1_VALOR"   , aParcelas[nY][2])
          oModelSZ1:SetValue("Z1_VENCTO"  , aParcelas[nY][1])
          oModelSZ1:SetValue("Z1_DTPAG"   , CToD("  /  /    "))
          oModelSZ1:SetValue("Z1_PEDIDO"  , SC5->C5_NUM)
          oModelSZ1:SetValue("Z1_CONDPAG" , SC5->C5_CONDPAG)

      EndIf
  Next nY

  For nY := 1 To 5
      If !Empty(SC5->&("C5_VEND"+(cValToChar(nY))))
        
        cCodVend := SC5->&("C5_VEND"+(cValToChar(nY)))
        cNomVend := Alltrim(Posicione("SA3",1,FWxFilial("SA3")+SC5->&("C5_VEND"+(cValToChar(nY))),"A3_NOME"))
        nPComis  := SC5->&("C5_COMIS"+(cValToChar(nY)))

        DBSelectArea("SZ2")
        SZ2->(DBSetOrder(2))
        If !SZ2->(DBSeek(FWxFilial("SZ2")+SC5->C5_NUM+cCodVend))

            If nY > 1 
              oModelSZ2:AddLine()
            EndIf
          
            oModelSZ2:SetValue("Z2_PEDIDO"  , SC5->C5_NUM)
            oModelSZ2:SetValue("Z2_PCOMIS"  , nPComis)
            oModelSZ2:SetValue("Z2_CODVEN"  , cCodVend)
            oModelSZ2:SetValue("Z2_NOMVEND" , cNomVend)

        EndIf
      EndIf 
  Next nY 

  oModelSZ1:GoLine(1)
  oView:Refresh('VIEW_SZ1')
  oModelSZ2:GoLine(1)
  oView:Refresh('VIEW_SZ2')
  oView:SetNoInsertLine('VIEW_SZ1')
  oView:SetNoInsertLine('VIEW_SZ2')

Return

/*---------------------------------------------------------------------*
 | Func:  zTotPed                                                      |
 | Desc:  Retorna o total do Pedido com os impostos                    |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
Static Function zTotPed(cNumPed)
Local aArea     := GetArea()
Local aAreaC5   := SC5->(GetArea())
Local aAreaB1   := SB1->(GetArea())
Local aAreaC6   := SC6->(GetArea())
Local cQryIte   := ""
Local nValPed   := 0
Local nNritem   := 0
        
        cQryIte := " SELECT "
        cQryIte += "    C6_ITEM, "
        cQryIte += "    C6_PRODUTO "
        cQryIte += " FROM "
        cQryIte += "    "+RetSQLName('SC6')+" SC6 "
        cQryIte += "    LEFT JOIN "+RetSQLName('SB1')+" SB1 ON ( "
        cQryIte += "        B1_FILIAL = '"+FWxFilial('SB1')+"' "
        cQryIte += "        AND B1_COD = SC6.C6_PRODUTO "
        cQryIte += "        AND SB1.D_E_L_E_T_ = ' ' "
        cQryIte += "    ) "
        cQryIte += " WHERE "
        cQryIte += "    C6_FILIAL = '"+FWxFilial('SC6')+"' "
        cQryIte += "    AND C6_NUM = '"+cNumPed+"' "
        cQryIte += "    AND SC6.D_E_L_E_T_ = ' ' "
        cQryIte += " ORDER BY "
        cQryIte += "    C6_ITEM "
        cQryIte := ChangeQuery(cQryIte)
        TCQuery cQryIte New Alias "QRY_ITE"
            
        DbSelectArea('SC5')
        SC5->(DbSetOrder(1))
        SC5->(DbSeek(FWxFilial('SC5') + cNumPed))
        MaFisIni(SC5->C5_CLIENTE,;                    // 1-Codigo Cliente/Fornecedor
            SC5->C5_LOJACLI,;                         // 2-Loja do Cliente/Fornecedor
            If(SC5->C5_TIPO$'DB',"F","C"),;           // 3-C:Cliente , F:Fornecedor
            SC5->C5_TIPO,;                            // 4-Tipo da NF
            SC5->C5_TIPOCLI,;                         // 5-Tipo do Cliente/Fornecedor
            MaFisRelImp("MT100",{"SF2","SD2"}),;      // 6-Relacao de Impostos que suportados no arquivo
            ,;                                        // 7-Tipo de complemento
            ,;                                        // 8-Permite Incluir Impostos no Rodape .T./.F.
            "SB1",;                                   // 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
            "MATA461")                                // 10-Nome da rotina que esta utilizando a funcao
            
        //Pega o total de itens
        QRY_ITE->(DbGoTop())
        While ! QRY_ITE->(EoF())
            nNritem++
            QRY_ITE->(DbSkip())
        EndDo
            
        //Preenchendo o valor total
        QRY_ITE->(DbGoTop())
        nTotIPI := 0
        While ! QRY_ITE->(EoF())
            //Pega os tratamentos de impostos
            SB1->(DbSeek(FWxFilial("SB1")+QRY_ITE->C6_PRODUTO))
            SC6->(DbSeek(FWxFilial("SC6")+cNumPed+QRY_ITE->C6_ITEM))
                
            MaFisAdd(   SC6->C6_PRODUTO,;                   // 1-Codigo do Produto              ( Obrigatorio )
                        SC6->C6_TES,;                       // 2-Codigo do TES                  ( Opcional )
                        SC6->C6_QTDVEN,;                    // 3-Quantidade                     ( Obrigatorio )
                        SC6->C6_PRCVEN,;                    // 4-Preco Unitario                 ( Obrigatorio )
                        0,;                                 // 5 desconto
                        SC6->C6_NFORI,;                     // 6-Numero da NF Original          ( Devolucao/Benef )
                        SC6->C6_SERIORI,;                   // 7-Serie da NF Original           ( Devolucao/Benef )
                        0,;                                 // 8-RecNo da NF Original no arq SD1/SD2
                        SC5->C5_FRETE/nNritem,;             // 9-Valor do Frete do Item         ( Opcional )
                        SC5->C5_DESPESA/nNritem,;           // 10-Valor da Despesa do item      ( Opcional )
                        SC5->C5_SEGURO/nNritem,;            // 11-Valor do Seguro do item       ( Opcional )
                        0,;                                 // 12-Valor do Frete Autonomo       ( Opcional )
                        SC6->C6_VALOR,;                     // 13-Valor da Mercadoria           ( Obrigatorio )
                        0,;                                 // 14-Valor da Embalagem            ( Opcional )
                        0,;                                 // 15-RecNo do SB1
                        0)                                  // 16-RecNo do SF4

            QRY_ITE->(DbSkip())
        EndDo
            
        //Pegando totais
        nTotIPI   := MaFisRet(,'NF_VALIPI')
        nTotICM   := MaFisRet(,'NF_VALICM')
        nTotNF    := MaFisRet(,'NF_TOTAL')
        nTotFrete := MaFisRet(,'NF_FRETE')
        nTotISS   := MaFisRet(,'NF_VALISS')
            
        QRY_ITE->(DbCloseArea())
        MaFisEnd()
        
    //Atualiza o retorno
    nValPed := nTotNF + nTotIPI + nTotFrete + nTotISS
        
    RestArea(aAreaC6)
    RestArea(aAreaB1)
    RestArea(aAreaC5)
    RestArea(aArea)
Return nValPed

/*---------------------------------------------------------------------*
 | Func:  LinePreGrid                                                  |
 | Desc:  Validações nas linhas do Grid                                |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
Static Function LinePreGrid(oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue)   
Local oModel := FWModelActive() 
Local oModelSZ2 := oModel:GetModel("SZ2DETAIL")
Local lRet      := .T.
Local nValComis := 0  
Local nId 
   
   If cAction == "SETVALUE"
      If cIDField == "Z1_MARK"
         DBSelectArea("SZ1")
         SZ1->(DBSetOrder(2))
         If SZ1->(DBSeek(FWxFilial("SZ1")+SC5->C5_NUM+SC5->C5_CONDPAG+FWFldGet("Z1_SEQ")))
            If SZ1->Z1_MARK
              lRet := .F. 
            EndIf
         EndIf

         If lRet 
            For nId := 1 To oModelSZ2:Length(.T.)
              
              oModelSZ2:SetLine(nId)
              nValComis := oModelSZ2:GetValue("Z2_VALOR")

              Do Case 
                  Case !xCurrentValue
                      
                      nValComis += Round(FWFldGet("Z1_VALOR") * (oModelSZ2:GetValue("Z2_PCOMIS")/100),2)
                      oModelSZ2:SetValue("Z2_VALOR", nValComis )

                  Case (xCurrentValue)
                      
                      nValComis := (nValComis - Round(FWFldGet("Z1_VALOR") * (oModelSZ2:GetValue("Z2_PCOMIS")/100),2))
                      oModelSZ2:SetValue("Z2_VALOR", nValComis )

              End Do 
            Next nId 
        EndIf         
      EndIf
   EndIf
   
Return lRet

/*---------------------------------------------------------------------*
 | Func:  FWProcess                                                    |
 | Desc:  Gera Pedido de Venda para emissão de NFS-e                   |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
Static Function FWProcess()
Local nId

Private oModel    := FWModelActive()
Private oModelSZ1 := oModel:GetModel("SZ1DETAIL")
Private oModelSZ2 := oModel:GetModel("SZ2DETAIL")
Private nValor    := 0
Private lMsHelpAuto := .T.
Private lMsErroAuto := .F. 
Private lRet        := .T.

For nId := 1 To oModelSZ1:Length(.T.)
  oModelSZ1:SetLine(nId)
  If oModelSZ1:IsUpdated(nId)
        
    nValor += oModelSZ1:GetValue("Z1_VALOR")

  EndIf 
Next nId

If nValor > 0
  RptStatus({|| FWProcNFSe()}, "Aguarde...", "Gravando Pedido de Venda...")
EndIf 

Return lRet

/*---------------------------------------------------------------------*
 | Func:  FWProcNFSe()                                                 |
 | Desc:  Grava Pedido de Venda para emissão da NFS-e                  |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
Static Function FWProcNFSe(oProcess)
Local aCabec    := {}
Local aItens    := {}
Local aLinha    := {}
Local cCondPag  := SuperGetMV("MV_CONDPAD")
Local cNaturez  := SuperGetMV("VZ_NATSERV")
Local cDescServ := SuperGetMV("VZ_DESCSER")
Local cCodProd  := SuperGetMV("VZ_PRDSERV")
Local cTES      := SuperGetMV("VZ_TESSERV")
Local nId 

      aadd(aCabec, {"C5_TIPO"   , "N",             Nil})
      aadd(aCabec, {"C5_CLIENTE", SC5->C5_XFABRIC, Nil})
      aadd(aCabec, {"C5_LOJACLI", SC5->C5_XLOJFAB, Nil})
      aadd(aCabec, {"C5_CONDPAG", cCondPag,        Nil})
      aadd(aCabec, {"C5_TIPLIB" , "1",             Nil})
      aadd(aCabec, {"C5_NATUREZ", cNaturez,        Nil})
      aadd(aCabec, {"C5_XMSGNFE", cDescServ,       Nil})
      For nId := 1 To oModelSZ2:Length(.T.)          
        oModelSZ2:SetLine(nId)
        If oModelSZ2:IsUpdated(nId)
            
            aadd(aCabec, {"C5_VEND"+(cValToChar(nId)),  oModelSZ2:GetValue("Z2_CODVEN"),  Nil})
            aadd(aCabec, {"C5_COMIS"+(cValToChar(nId)), oModelSZ2:GetValue("Z2_PCOMIS"),  Nil})

        EndIf 
      Next nId

      aLinha := {}
      aadd(aLinha,{"C6_ITEM",    "01",      Nil})
      aadd(aLinha,{"C6_PRODUTO", cCodProd,  Nil})
      aadd(aLinha,{"C6_QTDVEN",  1,         Nil})
      aadd(aLinha,{"C6_PRCVEN",  nValor,    Nil})
      aadd(aLinha,{"C6_PRUNIT",  nValor,    Nil})
      aadd(aLinha,{"C6_TES",     cTES,      Nil})
      aadd(aItens, aLinha)
      
      
      Begin Transaction
          SetRegua(1)
          IncRegua()
          lMsErroAuto := .F.
          MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, 3, .F.)
          
          If lMsErroAuto
              MostraErro()
              DisarmTransaction()
              lRet := .F.
          Else 
            FWAlertSuccess("Pedido de Venda: "+SC5->C5_NUM+", gravado com sucesso.", "Pedido de Venda (Serviço)")
          EndIf
      End Transaction
   
Return
