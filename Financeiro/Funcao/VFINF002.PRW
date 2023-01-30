#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

#Define PULALIN  Chr(10)

/*/{Protheus.doc} User Function VFINF002
    Funcao responsável por excluir o Título a Pagar da comissão do Vendedor, 
    e exclusão Pedido de Venda para emissão de NFS-e ao Fornecedor.
    @type  VFINF002
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 24/01/2023
    @version 1.0
/*/

User Function VFINF002()
Local aArea     := GetArea()

Private lMsHelpAuto := .T. 
Private lMsErroAuto := .F.

FWMsgRun(, {|| fExcPagar()  }, "Aguarde...","Excluindo Título a pagar de comissão para os Vendedores.")
FWMsgRun(, {|| fExcPedido() }, "Aguarde...","Excluindo Pedido de Venda para emissão da NFS-e.")

RestArea(aArea)

Return

/*/{Protheus.doc} fExcPagar
    Funcao para excluir o contas a pagar para os vendedores do Pedido de Venda (Agenciamento)
    @type  Static Function
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 24/01/2023
    @version 1.0
/*/

Static Function fExcPagar(oSay)
Local aVetSE2 := {}
Local _cAlias := GetNextAlias()  

IF _nOper == 5 //Exclusão
    
    DbSelectArea("SC5")
    SC5->(DbSetOrder(1))
    If SC5->(DBSeek(FWxFilial("SC5")+SE1->E1_XPEDIDO))
          
        BeginSql Alias _cAlias
            SELECT *
            FROM
                %table:SE2% 
            WHERE
                E2_FILIAL  = %xFilial:SE2%
                AND E2_PREFIXO = 'AGE'
                AND E2_TIPO    = 'AGE'
                AND E2_XIDTIT  = %Exp:cIDOrig%
                AND %notDel%
        EndSql        

        While !(_cAlias)->(EoF())
    
            DbSelectArea("SE2")
            SE2->(DbSetOrder(1))
            If SE2->(DBSeek((_cAlias)->E2_FILIAL+(_cAlias)->E2_PREFIXO+;
                            (_cAlias)->E2_NUM+(_cAlias)->E2_PARCELA+;
                            (_cAlias)->E2_TIPO))  

                    aAdd(aVetSE2, {"E2_FILIAL" , (_cAlias)->E2_FILIAL   ,Nil})
                    aAdd(aVetSE2, {"E2_PREFIXO", (_cAlias)->E2_PREFIXO  ,Nil})
                    aAdd(aVetSE2, {"E2_NUM"    , (_cAlias)->E2_NUM      ,Nil})
                    
                    /*
                    aAdd(aVetSE2, {"E2_PARCELA", (_cAlias)->E2_PARCELA  ,Nil})
                    aAdd(aVetSE2, {"E2_TIPO"   , (_cAlias)->E2_TIPO     ,Nil})
                    aAdd(aVetSE2, {"E2_NATUREZ", (_cAlias)->E2_NATUREZ  ,Nil})
                    aAdd(aVetSE2, {"E2_FORNECE", (_cAlias)->E2_FORNECE  ,Nil})
                    aAdd(aVetSE2, {"E2_LOJA"   , (_cAlias)->E2_LOJA     ,Nil})
                    aAdd(aVetSE2, {"E2_EMISSAO", (_cAlias)->E2_EMISSAO  ,Nil})
                    aAdd(aVetSE2, {"E2_VENCTO" , (_cAlias)->E2_VENCTO   ,Nil})
                    aAdd(aVetSE2, {"E2_VALOR"  , (_cAlias)->E2_VALOR    ,Nil})
                    aAdd(aVetSE2, {"E2_HIST"   , (_cAlias)->E2_HIST     ,Nil})
                    aAdd(aVetSE2, {"E2_XIDTIT" , cIDOrig                ,Nil})
                    */
                        Begin Transaction
                            
                            MsExecAuto({|x,y,z|FINA050(x,y,z)},aVetSE2,, _nOper)
                            //MSExecAuto({|x,y| FINA050(x,y)}, aVetSE2, _nOper)
                            
                            If lMsErroAuto
                                MostraErro()
                                DisarmTransaction()
                            EndIf 
                        
                        End Transaction
                 
            EndIf
         
         (_cAlias)->(DBSkip())
        ENDDO

    EndIf

EndIf 

If SELECT(_cAlias) > 0
    (_cAlias)->(DBCLOSEAREA())
EndIf 

Return

/*/{Protheus.doc} fExcPedido
    Funcao para excluir o contas a pagar para os vendedores do Pedido de Venda (Agenciamento)
    @type  Static Function
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 24/01/2023
    @version 1.0
/*/
Static Function fExcPedido(oSay)

Local aCabec    := {}
Local aItens    := {}
Local aLinha    := {}
Local cNumPed   := ""
Local _cAlias   := GetNextAlias()
Local cProdServ := SuperGetMV("VZ_PRDSERV",.F.,"")
Local cTESServ  := SuperGetMV("VZ_TESSERV",.F.,"")

IF _nOper == 5  //Exclusão

    BeginSql Alias _cAlias
        SELECT *
        FROM
            %table:SC5% 
        WHERE
            C5_FILIAL  = %xFilial:SC5%
            AND C5_XIDTIT  = %Exp:cIDOrig%
            AND %notDel%
    EndSql
    
    DbSelectArea("SC5")
    SC5->(DbSetOrder(1))
    If SC5->(DBSeek((_cAlias)->C5_FILIAL+(_cAlias)->C5_NUM))

            aadd(aCabec,{"C5_FILIAL" ,xFilial("SC5")        ,Nil})
            aadd(aCabec,{"C5_NUM"    ,(_cAlias)->C5_NUM     ,Nil})
            aadd(aCabec,{"C5_TIPO"   ,"N"                   ,Nil})  
            aadd(aCabec,{"C5_CLIENTE",(_cAlias)->C5_CLIENTE ,Nil})    
            aadd(aCabec,{"C5_LOJACLI",(_cAlias)->C5_LOJACLI ,Nil})  
            aadd(aCabec,{"C5_CONDPAG",(_cAlias)->C5_CONDPAG ,Nil})
            aadd(aCabec,{"C5_XIDTIT" ,cIDOrig               ,Nil})

            aadd(aLinha,{"C6_ITEM"   ,"01"          ,Nil})
            aadd(aLinha,{"C6_PRODUTO",cProdServ     ,Nil})   
            aadd(aLinha,{"C6_QTDVEN" ,1             ,Nil})   
            aadd(aLinha,{"C6_PRCVEN" ,1             ,Nil})   
            aadd(aLinha,{"C6_PRUNIT" ,1             ,Nil})   
            aadd(aLinha,{"C6_TES"    ,cTESServ      ,Nil})   
            aadd(aItens,aLinha)

            cNumPed := (_cAlias)->C5_NUM

            lMsHelpAuto := .T. 
            lMsErroAuto := .F.

            Begin Transaction

                MsExecAuto({|x, y, z| MATA410(x, y, z)}, aCabec, aItens, _nOper)

                If lMsErroAuto
                    MostraErro()
                    DisarmTransaction()
                EndIf

            End Transaction

    EndIf 
EndIf 

If SELECT(_cAlias) > 0
    (_cAlias)->(DBCLOSEAREA())
EndIF 

Return
