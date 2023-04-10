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
@SINCE 17/03/2023
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
Local bLoadZ1    := {|oStructSZ1, lCopy| LoadGridZ1(oStructSZ1, lCopy)}
Local bLoadZ2    := {|oStructSZ2, lCopy| LoadGridZ2(oStructSZ2, lCopy)}
Local bLinePre   := {||!FWFldGet("Z1_MARK")}

    //Criando o modelo e os relacionamentos
    oModel := MPFormModel():New('VFATF02M')
    oModel:AddFields('SC5MASTER',/*cOwner*/,oStructSC5)
	  oModel:AddGrid('SZ1DETAIL','SC5MASTER',oStructSZ1,bLinePre,/*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,bLoadZ1)
    oModel:AddGrid('SZ2DETAIL','SC5MASTER',oStructSZ2,/*bLinePre*/,/*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,bLoadZ2)
    
    oModel:SetRelation('SZ1DETAIL',{{'Z1_FILIAL','FWxFilial("SZ1")'},;
                                    {'Z1_PEDIDO','C5_NUM'          };
                                   }, SZ1->(IndexKey(1)))

    oModel:SetRelation('SZ2DETAIL',{{'Z2_FILIAL','FWxFilial("SZ2")'},;
                                    {'Z2_PEDIDO','C5_NUM'          };
                                   }, SZ2->(IndexKey(1)))

	  oModel:SetPrimaryKey({})

    //oStructSZ1:SetProperty("Z1_MARK", MODEL_FIELD_WHEN, {||!FWFldGet("Z1_MARK")})
    //oStructSZ1:SetLPre({||!FWFldGet("Z1_MARK")})
    oStructSZ1:AddTrigger("Z1_MARK" ,"Z1_DTPAG" ,{||.T.},{||dDataBase})

    oModel:GetModel('SZ1DETAIL'):SetOptional(.T.)
    oModel:GetModel('SZ2DETAIL'):SetOptional(.T.)

    oModel:SetDescription("Pedido de Venda - Agenciamento")
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

//-------------------------------------------------------------------
/*/ Função LoadGridZ1()
  Carga de Dados no Grid da SZ1 - Parcelas
/*/
//-------------------------------------------------------------------

Static Function LoadGridZ1(oStructSZ1, lCopy)
Local aLoad     := {}
Local nTotalPed := zTotPed(SC5->C5_NUM)
Local aParcelas := Condicao(nTotalPed,SC5->C5_CONDPAG,0,SC5->C5_EMISSAO,0) //Condicao(nValTot,cCond,nVIPI,dData,nVSol)
Local nY 

    For nY := 1 To Len(aParcelas)
      DBSelectArea("SZ1")
      SZ1->(DBSetOrder(2))
      If !SZ1->(DBSeek(FWxFilial("SZ1")+SC5->C5_NUM+SC5->C5_CONDPAG+StrZero(nY,3)))
        aAdd(aLoad,{0,{FWxFilial("SZ1"),;     //Z1_FILIAL
                     .F.,;                    //Z1_MARK
                     StrZero(nY,3),;          //Z1_SEQ
                     aParcelas[nY][2],;       //Z1_VALOR
                     aParcelas[nY][1],;       //Z1_VENCTO
                     CToD("  /  /    "),;     //Z1_DTPAG
                     SC5->C5_NUM,;            //Z1_PEDIDO
                     SC5->C5_CONDPAG}})       //Z1_CONDPAG 
          
          //Grava dados na Tabla
          RecLock("SZ1", .T.)	
            SZ1->Z1_FILIAL  := FWxFilial("SZ1")	
            SZ1->Z1_MARK    := .F.
            SZ1->Z1_SEQ     := StrZero(nY,3)
            SZ1->Z1_VALOR   := aParcelas[nY][2]
            SZ1->Z1_VENCTO  := aParcelas[nY][1]
            SZ1->Z1_DTPAG   := CToD("  /  /    ")
            SZ1->Z1_PEDIDO  := SC5->C5_NUM
            SZ1->Z1_CONDPAG := SC5->C5_CONDPAG
          SZ1->(MsUnLock())

        Else 

          aAdd(aLoad,{0,{FWxFilial("SZ1"),;   //Z1_FILIAL
                     SZ1->Z1_MARK,;           //Z1_MARK
                     SZ1->Z1_SEQ,;            //Z1_SEQ
                     SZ1->Z1_VALOR,;          //Z1_VALOR
                     SZ1->Z1_VENCTO,;         //Z1_VENCTO
                     SZ1->Z1_DTPAG,;          //Z1_DTPAG
                     SZ1->Z1_PEDIDO,;         //Z1_PEDIDO
                     SZ1->Z1_CONDPAG}})       //Z1_CONDPAG  
        
      EndIf
    Next nY 

Return aLoad

//-------------------------------------------------------------------
/*/ Função LoadGridZ2()
  Carga de Dados no Grid da SZ2 - Vendedores
/*/
//-------------------------------------------------------------------
Static Function LoadGridZ2(oStructSZ2, lCopy)
Local aLoad    := {}
Local cCodVend := ""
Local cNomVend := ""
Local nPComis  := 0
Local nY

    For nY := 1 To 5
      If !Empty(SC5->&("C5_VEND"+(cValToChar(nY))))
        
        cCodVend := SC5->&("C5_VEND"+(cValToChar(nY)))
        cNomVend := Alltrim(Posicione("SA3",1,FWxFilial("SA3")+SC5->&("C5_VEND"+(cValToChar(nY))),"A3_NOME"))
        nPComis  := SC5->&("C5_COMIS"+(cValToChar(nY)))

        DBSelectArea("SZ2")
        SZ2->(DBSetOrder(2))
        If !SZ2->(DBSeek(FWxFilial("SZ2")+SC5->C5_NUM+cCodVend))

            aAdd(aLoad,{0,{FWxFilial("SZ2"),SC5->C5_NUM,nPComis,cCodVend,cNomVend}}) 

            //Grava dados na Tabla
            RecLock("SZ2", .T.)	
              SZ2->Z2_FILIAL  := FWxFilial("SZ2")	
              SZ2->Z2_PEDIDO  := SC5->C5_NUM
              SZ2->Z2_PCOMIS  := nPComis
              SZ2->Z2_CODIGO  := cCodVend
              SZ2->Z2_NOME    := cNomVend
            SZ2->(MsUnLock())
          Else 

            aAdd(aLoad,{0,{FWxFilial("SZ2"),SZ2->Z2_PEDIDO,SZ2->Z2_PCOMIS,SZ2->Z2_CODIGO,SZ2->Z2_NOME}}) 
        
        EndIf
      EndIf 
    Next nY  

Return aLoad

//-------------------------------------------------------------------
/*/ Função zTotPed()
  Retorna o total do Pedido com os impostos
/*/
//-------------------------------------------------------------------
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
