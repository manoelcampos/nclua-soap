---Aplicação de exemplo que consume Web Service http://www.maniezo.com.br/webservice/soap-server.php
--para obtenção de endereço a partir do CEP
--@author Manoel Campos da Silva Filho<br>
--<a href="http://manoelcampos.com">http://manoelcampos.com</a>

--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'


require "ncluasoap"

---Finaliza o script lua. Um link no NCL finalizará a aplicação NCL quando o nó lua for finalizado
local function stopPresentation()
  event.post {class="ncl", type="presentation", action="stop"}
end


---Função para processar a resposta da requisição SOAP enviada ao WS de busca de endereço a partir de um cep
--@param result Resultado da chamada ao método remoto via SOAP, contendo o endereço no formato:
--tipo_logradouro#endereco#complemento#bairro#cidade#uf
--No caso deste Web Service, o resultado é uma variável primitiva simples (ou seja, contendo apenas um valor)
local function getResponse(result)
   --Forma de uso com NCLua SOAP anterior a 0.5.6
   --return é o nome da chave na qual o valor retornado pelo WS é armazenado, como apresentado no XML de retorno
   --print(result["return"]) 
   local i = 0
   
   i = string.find(result, '#')
   local tipo = string.sub(result, 1, i-1)
   result = string.sub(result, i+1)
   
   i = string.find(result, '#')
   local endereco = string.sub(result, 1, i-1)
   result = string.sub(result, i+1)
   
   i = string.find(result, '#')
   local complemento = string.sub(result, 1, i-1)
   result = string.sub(result, i+1)
   
   i = string.find(result, '#')
   local bairro = string.sub(result, 1, i-1)
   result = string.sub(result, i+1)
   
   i = string.find(result, '#')
   local cidade = string.sub(result, 1, i-1)
   result = string.sub(result, i+1)
   
   local uf = result
   
   print("\n\n\n--------------------------------RESULTADO--------------------------------")
   print("                                 Tipo logradouro:", tipo)
   print("                                 Endereço:", endereco)
   print("                                 Complemento:", complemento)
   print("                                 Bairro:", bairro)
   print("                                 Cidade:", cidade)
   print("                                 UF:", uf)
   print("--------------------------------RESULTADO--------------------------------\n\n\n")
   
   stopPresentation()
end

   

--Informe seu login/senha cadastrados em www.maniezo.com.br    
local login = "" 
local senha = ""
local cep = "77021682"

local msgTable = {
  address = "http://www.maniezo.com.br/webservice/soap-server.php",
  namespace = "http://www.maniezo.com.br",
  operationName = "traz_cep",
  params = {
    cep = cep.."#"..login.."#"..senha.."#"
  }  
}
   
--Para usar o webservice do site maniezo.com.br, é necessário fazer
--cadastro para obter um login e senha a ser
--usado no envio da requisição. Estes dados devem
--ser informados nas variáveis login e senha acima
ncluasoap.call(msgTable, getResponse, "1.1")
