#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

#Define PULALIN  Chr(10)

/*/{Protheus.doc} User Function VFINF001
    Funcao responsável por gerar o Título a Pagar da comissão do Vendedor, 
    e Inclusão Pedido de Venda para emissão de NFS-e ao Fornecedor.
    @type  VFINF001
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 26/01/2023
    @version 1.0
/*/

User Function VFINF001()
Local aArea     := GetArea()
Local aPergs    := {}
Local aRetorn   := {}

Private nPVendedor  := 0
Private lMsHelpAuto := .T. 
Private lMsErroAuto := .F.

//Adiciona os parâmetro para a pergunta
aAdd(aPergs, {1, "Percentual Vendedor", nPVendedor, "@E 99.99",,,, 50, .T.})
	
//Se a pergunta for confirmada
If ParamBox(aPergs, "Informe o percentual de comissão para o vendedor.", @aRetorn, , , , , , , , .F., .F.)
	nPVendedor   := aRetorn[1]

    If FWMsgRun(, {|oSay| fGeraPagar(oSay)  }, "Aguarde...","Gerando Título a pagar de comissão para os Vendedores.")
        If FWAlertNoYes("Ocorreu um erro na geração do título a pagar, deseja continuar com a baixa do título?",;
                        "Erro na geração do título a pagar da comissão.")
            lRet := .T.
         else 
        
            Return lRet
        
        EndIf 
    EndIf 
    
    If FWMsgRun(, {|oSay| fGeraPedido(oSay) }, "Aguarde...","Gerando Pedido de Venda para emissão da NFS-e.")
        If FWAlertNoYes("Ocorreu um erro na geração do Pedido de Venda, deseja continuar com a baixa do título?",;
                        "Erro na geração do Pedido de Venda da NFS-e.")
            lRet := .T.
         else 

            Return lRet

        EndIf 
    EndIf
EndIf

RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGeraPagar
    Funcao para gerar o contas a pagar para os vendedores do Pedido de Venda (Agenciamento)
    @type  Static Function
    @author TOTVS Nordeste (Elvis Siqueira)
    @version 1.0
/*/
Static Function fGeraPagar(oSay)
Local aVetSE2   := {}
Local cNumero   := ""
Local cNatureza := SuperGetMV("VZ_NATAGEP",.F.,"")
Local cHist     := SuperGetMV("VZ_HISAGEP",.F.,"")
Local cIDTitulo := "" 
Local nDays     := SuperGetMV("VZ_DAYAGEP",.F.,0)
Local dDataSum  := DaySum(dDataBase,nDays)
Local nValor    := 0
Local nX 

IF _nOper == 3 
    DbSelectArea("SC5")
    SC5->(DbSetOrder(1))
    If SC5->(DBSeek(FWxFilial("SC5")+SE1->E1_XPEDIDO))
            
        For nX := 1 To 5
            DbSelectArea("SA3")
            SA3->(DbSetOrder(1))
            If SA3->(DBSeek(FWxFilial("SA3")+&("SC5->C5_VEND"+(CValToChar(nX)))))
                
                If !Empty(SA3->A3_FORNECE)
                    cNumero   := GetSxeNum("SE2","E2_NUM",xFilial("SE2")+"AGE")
                    cIDTitulo := SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO
                    nValor    := Round(nValRec * (nPVendedor/100),2)

                        aVetSE2 := {}

                        aAdd(aVetSE2, {"E2_FILIAL" , FWxFilial("SE2") ,Nil})
                        aAdd(aVetSE2, {"E2_NUM"    , cNumero          ,Nil})
                        aAdd(aVetSE2, {"E2_PREFIXO", "AGE"            ,Nil})
                        aAdd(aVetSE2, {"E2_PARCELA", "01"             ,Nil})
                        aAdd(aVetSE2, {"E2_TIPO"   , "AGE"            ,Nil})
                        aAdd(aVetSE2, {"E2_NATUREZ", cNatureza        ,Nil})
                        aAdd(aVetSE2, {"E2_FORNECE", SA3->A3_FORNECE  ,Nil})
                        aAdd(aVetSE2, {"E2_LOJA"   , SA3->A3_LOJA     ,Nil})
                        aAdd(aVetSE2, {"E2_EMISSAO", dDataBase        ,Nil})
                        aAdd(aVetSE2, {"E2_VENCTO" , dDataSum         ,Nil})
                        aAdd(aVetSE2, {"E2_VALOR"  , nValor           ,Nil})
                        aAdd(aVetSE2, {"E2_HIST"   , cHist            ,Nil})
                        aAdd(aVetSE2, {"E2_XIDTIT" , cIDTitulo        ,Nil})

                        Begin Transaction
                        
                            lMsHelpAuto := .T. 
                            lMsErroAuto := .F.

                            MSExecAuto({|x,y| FINA050(x,y)}, aVetSE2, _nOper)
                                
                            If lMsErroAuto
                                RollBackSX8()
                                MostraErro()
                                DisarmTransaction()
                            else
                                lRet := .T.
                                FWAlertSuccess("O Título "+cNumero+", foi incluído com sucesso!", "Inclusão de Título (Agenciamento)")
                            EndIf 
                        
                        End Transaction
                 else 
                    
                    FWAlertWarning("O vendedor(a) "+Alltrim(SA3->A3_NOME)+", encontra-se com o campo Cod. Fornecedor em branco."+;
                                   "Por este motivo, não será gravado o título de comissão para o mesmo.",;
                                   "Cadastro de Vendedores")
                
                EndIf  
             ElseIf nX == 1 

                FWAlertWarning("Nenhum vendedor encontrado para geração do título.",;
                            "Geração de título a pagar da comissão.")

                Return lRet

            EndIf 
        Next nX 

    EndIf 
EndIF 

Return lRet

/*/{Protheus.doc} fGeraPedido
    Funcao para gerar o contas a pagar para os vendedores do Pedido de Venda (Agenciamento)
    @type  Static Function
    @author TOTVS Nordeste (Elvis Siqueira)
    @version 1.0
/*/
Static Function fGeraPedido(oSay)

Local aCabec    := {}
Local aItens    := {}
Local aLinha    := {}
Local cNumPed   := ""
Local cProdServ := SuperGetMV("VZ_PRDSERV",.F.,"")
Local cDecServ  := SuperGetMV("VZ_DESCSER",.F.,"")
Local cTESServ  := SuperGetMV("VZ_TESSERV",.F.,"")
Local cCampoSrv := SuperGetMV("MV_CMPUSR" ,.F.,"")
Local cCondPad  := SuperGetMV("MV_CONDPAD",.F.,"")
Local cNatPedSV := SuperGetMV("VZ_NATSERV",.F.,"")
Local cIDTitulo := SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO

    aadd(aCabec,{"C5_FILIAL" ,xFilial("SC5")  ,Nil})
    aadd(aCabec,{"C5_NUM"    ,cNumPed         ,Nil})  
    aadd(aCabec,{"C5_TIPO"   ,"N"             ,Nil})  
    aadd(aCabec,{"C5_CLIENTE",SE1->E1_CLIENTE ,Nil})    
    aadd(aCabec,{"C5_LOJACLI",SE1->E1_LOJA    ,Nil})  
    aadd(aCabec,{"C5_CONDPAG",cCondPad        ,Nil})
    aadd(aCabec,{"C5_NATUREZ",cNatPedSV       ,Nil})
    aadd(aCabec,{"C5_XIDTIT" ,cIDTitulo       ,Nil})
    aadd(aCabec,{cCampoSrv   ,cDecServ        ,Nil})

    aadd(aLinha,{"C6_ITEM"   ,"01"            ,Nil}) 
    aadd(aLinha,{"C6_PRODUTO",cProdServ       ,Nil})   
    aadd(aLinha,{"C6_QTDVEN" ,1               ,Nil})   
    aadd(aLinha,{"C6_PRCVEN" ,nValRec         ,Nil})   
    aadd(aLinha,{"C6_PRUNIT" ,nValRec         ,Nil})   
    aadd(aLinha,{"C6_TES"    ,cTESServ        ,Nil}) 
    aadd(aItens,aLinha)

        IF _nOper == 3  //Inclusão 

            cNumPed   := GetSxeNum("SC5","C5_NUM") 
            aCabec[2][2] := cNumPed

            Begin Transaction

                MsExecAuto({|x, y, z| MATA410(x, y, z)}, aCabec, aItens, _nOper)

                If lMsErroAuto
                    RollBackSX8()
                    MostraErro()
                    DisarmTransaction()
                 else
                    lRet := .T.
                    FWAlertSuccess("Pedido de Venda "+cNumPed+", foi incluído com sucesso!", "Inclusão de Pedido de Venda (Agenciamento)")
                EndIf

            End Transaction

        EndIf 

Return lRet
