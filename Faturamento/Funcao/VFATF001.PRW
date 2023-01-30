#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#Include "TOPCONN.ch"

#Define PULALIN  Chr(10)

/*/{Protheus.doc} User Function VFATF001
    Funcao para criar Contas a Receber e Pedido de Venda para emissão de NFS-e
    @type  VFATF001
    @author TOTVS Nordeste (Elvis Siqueira)
    @since 16/01/2023
    @version 1.0
/*/

User Function VFATF001()
Local aVetSE1   := {}
Local cNumero   := ""
Local cNatureza := SuperGetMV("VZ_NATAGER",.F.,"")
Local cHist     := SuperGetMV("VZ_HISAGER",.F.,"") 
Local _cAlias   := GetNextAlias()
Local nDays     := SuperGetMV("VZ_DAYAGER",.F.,0)
Local dDataSum  := DaySum(C5_EMISSAO,nDays)
Local nPComis   := SC5->C5_XPERCEN
Local nValor    := 0

Private lMsHelpAuto := .T. 
Private lMsErroAuto := .F. 

    DbSelectArea("SC6")
    SC6->(DbSetOrder(1))
    If SC6->(DBSeek(FWxFilial("SC6")+SC5->C5_NUM))
        While ! SC6->(EoF())
            nValor := nValor + SC6->C6_VALOR
         SC6->(DbSkip())
        EndDo
    EndIf 
    
    nValor := Round(nValor * (nPComis/100),2)

    aAdd(aVetSE1, {"E1_FILIAL" , FWxFilial("SE1") ,Nil})
    aAdd(aVetSE1, {"E1_NUM"    , cNumero          ,Nil})
    aAdd(aVetSE1, {"E1_PREFIXO", "AGE"            ,Nil})
    aAdd(aVetSE1, {"E1_PARCELA", "01"             ,Nil})
    aAdd(aVetSE1, {"E1_TIPO"   , "AGE"            ,Nil})
    aAdd(aVetSE1, {"E1_NATUREZ", cNatureza        ,Nil})
    aAdd(aVetSE1, {"E1_CLIENTE", C5_XFORNEC       ,Nil})
    aAdd(aVetSE1, {"E1_LOJA"   , C5_XLOJFOR       ,Nil})
    aAdd(aVetSE1, {"E1_EMISSAO", C5_EMISSAO       ,Nil})
    aAdd(aVetSE1, {"E1_VENCTO" , dDataSum         ,Nil})
    aAdd(aVetSE1, {"E1_VALOR"  , nValor           ,Nil})
    aAdd(aVetSE1, {"E1_HIST"   , cHist            ,Nil})
    aAdd(aVetSE1, {"E1_XPEDIDO", C5_NUM           ,Nil})

    If _nOper == 3
        cNumero := GetSxeNum("SE1","E1_NUM",xFilial("SE1")+"AGE")
        aVetSE1[2][2] := cNumero
             
    ElseIf _nOper <> 3
                
        BeginSql Alias _cAlias
            SELECT *
            FROM
                %table:SE1% 
            WHERE
                E1_FILIAL  = %xFilial:SE1%
                AND E1_PREFIXO = 'AGE'
                AND E1_TIPO    = 'AGE'
                AND E1_XPEDIDO = %Exp:SC5->C5_NUM%
                AND %notDel%
        EndSql

        DbSelectArea('SE1')
        SE1->(DbSetOrder(1))
        If SE1->(DBSeek(xFilial("SE1")+(_cAlias)->E1_PREFIXO+(_cAlias)->E1_NUM+;
                        (_cAlias)->E1_PARCELA+(_cAlias)->E1_TIPO))

            aVetSE1[2][2]  := (_cAlias)->E1_NUM
            aVetSE1[9][2]  := SToD((_cAlias)->E1_EMISSAO)
            aVetSE1[10][2] := SToD((_cAlias)->E1_VENCTO)
            aVetSE1[11][2] := nValor

         else 
            If _nOper <> 5       
                _nOper := 3
                cNumero := GetSxeNum("SE1","E1_NUM",xFilial("SE1")+"AGE")
                aVetSE1[2][2] := cNumero
             else 
                Return
            EndIf 
        EndIf 
    EndIF 

    Begin Transaction
                
        MSExecAuto({|x,y| FINA040(x,y)}, aVetSE1, _nOper)
                
        If lMsErroAuto
            MostraErro()
            
            If _nOper == 3
                RollBackSX8()
            EndIF 
            
            DisarmTransaction()
         else 
            Do Case     
                Case _nOper == 3
                    FWAlertSuccess("O Título "+cNumero+", foi incluído com sucesso!", "Inclusão de Título (Agenciamento)")
                Case _nOper == 4                
                    FWAlertSuccess("O Título "+(_cAlias)->E1_NUM+", foi alterado com sucesso!", "Alteração de Título (Agenciamento)")
                Case _nOper == 5
                    FWAlertSuccess("O Título "+(_cAlias)->E1_NUM+", foi excluído com sucesso!", "Exclusão de Título (Agenciamento)")
            EndCase 
        EndIf 
            
    End Transaction

Return
