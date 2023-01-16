#Include "PROTHEUS.CH"
#Include "TopConn.CH"

/*/{protheusDoc.marcadores_ocultos} MATA110
  Função MT110ROT
  @parâmetro Nã há
  @author Totvs Nordeste - Anderson Almeida

  @sample
 // MT110ROT - No inico da rotina e antes da execução da Mbrowse da SC, utilizado
               para adicionar mais opções no aRotina.

  Return aRotina - rotina com a chamado do programa
  @historia
  25/02/2021 - Desenvolvimento da Rotina.
/*/
User Function MT110ROT()
//Define Array contendo as Rotinas a executar do programa
 // ----------- Elementos contidos por dimensao ------------
     // 1. Nome a aparecer no cabecalho
     // 2. Nome da Rotina associada
     // 3. Usado pela rotina
     // 4. Tipo de Transação a ser efetuada
     //    1 - Pesquisa e Posiciona em um Banco de Dados
     //    2 - Simplesmente Mostra os Campos
     //    3 - Inclui registros no Bancos de Dados
     //    4 - Altera o registro corrente
     //    5 - Remove o registro corrente do Banco de Dados
     //    6 - Altera determinados campos sem incluir novos Regs
  aAdd(aRotina, {"E-Mail Aprovador","U_ACOMW055(3,Nil,SC1->C1_NUM)",0,4})
Return aRotina 
