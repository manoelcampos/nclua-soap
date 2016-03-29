---Exemplo para acesso a Web Service de conversão de Fahrenheit para Celcius

--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'

require "ncluasoap"

local fahrenheit = 212

---Função para processar a resposta da requisição SOAP enviada ao WS
--@param result Resultado da chamada ao método remoto via SOAP.
--No caso deste Web Service, o resultado é uma variável primitiva simples (ou seja, contendo apenas um valor)
local function getResponse(result)
   --Forma de uso com NCLua SOAP anterior a 0.5.6
   --O nome do elemento que contém o retorno é obtido no WSDL ou no XML de retorno
   --print("\n\n\n---------------" .. fahrenheit.." Fahrenheit em Celcius = "..result["m:FahrenheitToCelciusResult"].."\n\n\n")
  
   print("\n\n\n--------------------------------RESULTADO--------------------------------")
   print("                     " .. fahrenheit.." Fahrenheit em Celcius = "..result)
   print("--------------------------------RESULTADO--------------------------------\n\n\n")

  --Finaliza o script lua. Um link no NCL finalizará a aplicação NCL quando o nó lua for finalizado
  event.post {class="ncl", type="presentation", action="stop"}
end

local msg = {
  address = "http://webservices.daehosting.com/services/TemperatureConversions.wso",
  namespace = "http://webservices.daehosting.com/temperature",
  operationName = "FahrenheitToCelcius",
  params = {
    nFahrenheit = fahrenheit
  }  
}

--O serviço sendo acessado só aceita SOAP 1.1
local soapVersion = "1.1"
ncluasoap.call(msg, getResponse, soapVersion)


