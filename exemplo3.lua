---Exemplo para acesso ao Web Service http://www.bronzebusiness.com.br/webservices/wscep.asmx
--para consulta de endereço pelo cep
--@author Manoel Campos da Silva Filho<br>
--<a href="http://manoelcampos.com">http://manoelcampos.com</a>


--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'

require "ncluasoap"
--require "util"

---Função para processar a resposta da requisição SOAP enviada ao WS
--@param result Resultado da chamada ao método remoto via SOAP.
--No caso deste Web Service, o resultado é uma tabela com vários campos.
local function getResponse(result)
   --O nome do elemento que contém o retorno é obtido no WSDL ou no XML de retorno
    
   --Forma de acesso em NCLua SOAP anterior a 0.5.6
   --result = result.cepResult["diffgr:diffgram"].NewDataSet.tbCEP
   --for k, v in pairs(result) do print(k, v) end

   print("\n\n\n--------------------------------RESULTADO--------------------------------")
   for k, v in pairs(result) do
      print("                      "..k..":", v)
   end
   print("--------------------------------RESULTADO--------------------------------\n\n\n")

   --Alternativa para imprimir todos os dados da tabela. Requer o uso do módulo util
   --util.printable(result)

   --Finaliza o script lua. Um link no NCL finalizará a aplicação NCL quando o nó lua for finalizado
   event.post {class="ncl", type="presentation", action="stop"}
end

local msg = {
  address = "http://www.bronzebusiness.com.br/webservices/wscep.asmx",
  namespace = "http://tempuri.org/",
  operationName = "cep",
  params = {
    strcep = "70855530"
  }  
}

ncluasoap.call(msg, getResponse)
