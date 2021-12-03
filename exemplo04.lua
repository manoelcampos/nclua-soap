---Exemplo para acesso a Web Service de consulta de feriados
--O SERVIÇO ESTAVA FORA DO AR NA ÚLTIMA VEZ QUE TENTOU-SE O ACESSO, EM 10/02/2011
--@author Manoel Campos da Silva Filho<br>
--<a href="http://manoelcampos.com">http://manoelcampos.com</a>


--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'

local ncluasoap = require "ncluasoap"

---Função para processar a resposta da requisição SOAP enviada ao WS
--@param result Resultado da chamada ao método remoto via SOAP.
--No caso deste Web Service, o resultado é uma tabela com vários campos.
local function getResponse(result)
   --Forma de uso com NCLua SOAP anterior a 0.5.6
   --O nome do elemento que contém o retorno é obtido no WSDL ou no XML de retorno
   --result = result.getFeriadosResult["diffgr:diffgram"].DocumentElement.Feriados
   -- for k, v in pairs(xmlTable) do print(k, v) end

   local data = ""
   print("\n\n\n-------------------------------Lista de Feriados")
   for k, feriado in pairs(result) do
       data = string.sub(feriado.Data, 1, 10)
       print("            "..data, feriado.Local, feriado.NomeFeriado)
   end
   print("------------------------------------------------------\n\n\n")

   --Alternativa para imprimir todos os dados da tabela. Requer o uso do módulo util
   --util.printable(result)

  --Finaliza o script lua. Um link no NCL finalizará a aplicação NCL quando o nó lua for finalizado
  event.post {class="ncl", type="presentation", action="stop"}
end

--Artigo sobre o WS de Feriados: http://www.tutools.net/tutools/wordpress/tutoriais/webservice-de-feriados/
--http://www.tutools.com.br/tutools/dicas-e-ferramentas/webservice/webservice-de-feriados/

local msg = {
  address = "http://feriados.tutools.net/feriados.asmx",
  namespace = "http://feriados.tutools.net",
  operationName = "getFeriados"
}

ncluasoap.call(msg, getResponse, "1.1")
