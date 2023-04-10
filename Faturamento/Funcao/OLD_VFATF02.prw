//Bibliotecas
#Include 'Protheus.ch'
#Include 'FwMVCDef.ch'
 
/*/{Protheus.doc} VFATF02
MarkBrow em MVC da tabela de Artistas
@author TOTVS Recife (Elvis Siqueira)
@since 17/03/2023
@version 1.0
/*/
 
User Function VFATF02()
    Private oMark
     
    //Criando o MarkBrow
    oMark := FWMarkBrowse():New()
    oMark:SetAlias('SZ1')
     
    //Setando semáforo, descrição e campo de mark
    oMark:SetSemaphore(.T.)
    oMark:SetDescription('Parcelas do Pedido de Venda: '+SC5->C5_NUM)
    oMark:SetFieldMark( 'Z1_STATUS' )
     
    //Setando Legenda
    oMark:AddLegend( "Empty(SZ1->Z1_STATUS)", "GREEN", "Parcela em aberto" )
    oMark:AddLegend( "Empty(SZ1->Z1_STATUS)", "RED"  , "Parcela em Paga" )
     
    //Ativando a janela
    oMark:Activate()
Return NIL
 
/*---------------------------------------------------------------------*
 | Func:  MenuDef                                                      |
 | Desc:  Criação do menu MVC                                          |
 *---------------------------------------------------------------------*/
  
Static Function MenuDef()
    Local aRotina := {}
     
    ADD OPTION aRotina TITLE 'Processar'  ACTION 'U_zProcessa()' OPERATION 2 ACCESS 0

Return aRotina
 
/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Desc:  Criação do modelo de dados MVC                               |
 *---------------------------------------------------------------------*/
  
Static Function ModelDef()
Return FWLoadModel('zModel1')
 
/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Desc:  Criação da visão MVC                                         |
 *---------------------------------------------------------------------*/
  
Static Function ViewDef()
Return FWLoadView('zModel1')
 
/*---------------------------------------------------------------------*
 | Func:  FAT02Process                                                 |
 | Desc:  Processa o pagamento das Parcelas marcadas pelo usuário      |
 *---------------------------------------------------------------------*/
 
User Function zProcessa()
    Local aArea    := GetArea()
    Local cMarca   := oMark:Mark()
    Local nCt      := 0
    //Local lInverte := oMark:IsInvert()
    
    SZ1->(DbGoTop())
    While !SZ1->(EoF())
        If oMark:IsMark(cMarca)
            nCt++

            RecLock('SZ1', .F.)
                Z1_STATUS := ''
            SZ1->(MsUnlock())
        EndIf
        
        SZ1->(DbSkip())
    EndDo
     
    RestArea(aArea)
Return NIL
