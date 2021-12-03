---Aplicação de exemplo que obtém a situação do tempo em determinada cidade
--@author Manoel Campos da Silva Filho<br>
--<a href="http://manoelcampos.com">http://manoelcampos.com</a>

--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'

local ncluasoap = require "ncluasoap"

---Finaliza o script lua. Um link no NCL finalizará a aplicação NCL quando o nó lua for finalizado
local function stopPresentation()
  event.post {class="ncl", type="presentation", action="stop"}
end

---Função para processar a resposta da requisição SOAP enviada ao WS de situação do tempo
--@param result Resultado da chamada ao método remoto via SOAP.
--No caso deste Web Service, o resultado é uma variável primitiva simples (ou seja, contendo apenas um valor)
local function getResponse(result)
  --Forma de uso com NCLua SOAP anterior a 0.5.6
  --print("\n\n---------Cotação do Dólar em Reais:", result.GetWeatherResult, "\n\n")

  print("\n\n\n--------------------------------RESULTADO--------------------------------")
  print("                  Situação do Tempo:", result)
  print("--------------------------------RESULTADO--------------------------------\n\n\n")

  stopPresentation()
end


local msgTable = {
  address = "http://www.deeptraining.com/webservices/weather.asmx",
  namespace = "http://litwinconsulting.com/webservices/",
  operationName = "GetWeather",
  params = {
    City = "Brasília"
  }  
}

ncluasoap.call(msgTable, getResponse)

