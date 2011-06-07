---Exemplo para acesso a Web Service de obtenção de lista de estados de uma determinada região do país.
--É feita uma chamada ao método remoto estados2, que no lugar de receber dois parâmetros (como o método estados),
--recebe apenas um parâmetro do tipo registro (como uma struct em C).
--A chamada ao método remoto em lua é feita passando-se uma table lua convencional,
--contendo chaves nomeadas.

--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'

require "ncluasoap"

---Função para processar a resposta da requisição SOAP enviada ao WS
--@param result Resultado da chamada ao método remoto via SOAP.
--No caso deste Web Service, o resultado é uma variável primitiva simples (ou seja, contendo apenas um valor)
local function getResponse(result)
   print("\n\n\n---------------Lista de Estados da Região Escolhida")

   --Forma de uso com NCLua SOAP anterior a 0.5.6
   --O nome do elemento que contém o retorno é obtido no WSDL ou no XML de retorno
   --print(result["return"])

   print(result)
   print("---------------------------------------------------\n\n\n")

  --Finaliza o script lua. Um link no NCL finalizará a aplicação NCL quando o nó lua for finalizado
  event.post {class="ncl", type="presentation", action="stop"}
end

local msg = {
  address = "http://manoelcampos.com/estadosws/server.php",
  namespace = "manoelcampos.com",
  operationName = "estados2",
  params = {
    --O método remoto estados2 deve receber uma tabela lua, contendo os campos ordem e regiao
    dados = {
      ordem = "estado", --Ordenar o resultado pelo nome do campo especificado (opções são: estado ou uf)
      regiao = "norte" ----Obter apenas os estados da região do país especificada
    } 
  }  
}


--O serviço sendo acessado só aceita SOAP 1.1
local soapVersion = "1.1"
ncluasoap.call(msg, getResponse, soapVersion)

