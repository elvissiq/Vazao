#Include "PROTHEUS.CH"
#Include "TopConn.CH"

// -------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} MATA106
  Fun��o MT106SC1
  @par�metro N� h�
  @author Totvs Nordeste - Elvis Siqueira

  @sample
 // MT106SC1 - Permite a manuten��o de dados armazenados 
               em ap�s a grava��o da SC.

  Return aRotina - rotina com a chamado do programa
  @historia
  15/09/2021 - Desenvolvimento da Rotina.
/*/
User Function MT106SC1()
  Local aArea  := GetArea()
  Local aDados := {ParamIxB[1], ParamIxB[2], ParamIxB[3]}

  If aDados[01] == "SC1"
     U_ACOMW055(3,Nil,aDados[02])
     
      SC1->(DbSetorder(1))
      If SC1->(DbSeek(FWxFilial("SC1")+aDados[02]+aDados[03]))
              RecLock("SC1", .F.)
                SC1->C1_OBS := "SC gerada por SA de N�: "+SCP->CP_NUM
              SC1->(MsUnlock())      
      EndIf 
  
  EndIf

  RestArea(aArea)   
Return 
