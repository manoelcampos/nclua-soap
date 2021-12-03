---Aplicação de Exemplo de consumo de WS desenvolvido em Java com a biblioteca JAX-WS.
--Veja documentação do método ncluasoap.call para mais detalhes.

--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'

local ncluasoap = require "ncluasoap"

local function getResponse(result)
  print("\n\n\n--------------------------------RESULTADO--------------------------------")
  print(result)
  print("--------------------------------RESULTADO--------------------------------\n\n\n")
  event.post {class="ncl", type="presentation", action="stop"}
end
 
--Cria uma table contendo os dados para envio da requisição SOAP ao WS
local msgTable = {
  address = "http://200.131.219.56:8080/MyWebService/MyWsService",
  --Namespace exatamente como especificado no WSDL, neste caso, terminando com /
  namespace = "http://lapic/",
  operationName = "teste",
  params = {
    a = "String de Teste"
  }
}

--O último parâmetro (externalXsd), de valor true, indica
--que o WS usa um arquivo XSD externo para especificar as definições
--de tipos. Isto influencia no formato da requisição SOAP.
--O valor padrão dele é false.
--Veja documentação do método ncluasoap.call para mais detalhes.
ncluasoap.call(msgTable, getResponse, "1.1", nil, true)

