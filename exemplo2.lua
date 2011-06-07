---Aplicação de exemplo que consome Web Service para obtenção
--do nome do país a qual pertencer determinado IP.
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
  
--Função usada para tratar a resposta da requisição
--do país ao qual um determinado IP está vinculado
--@param result Resultado da chamada ao método remoto via SOAP.
--No caso deste Web Service, o resultado é uma variável simples (ou seja, com apenas um valor)
--contendo a sigla do país associado ao IP informado
local function getResponse(result)
   --Forma de uso com NCLua SOAP anterior a 0.5.6
   --print("                                 Country:", result.FindCountryAsXmlResult.IPCountryService.Country)
   
   print("\n\n\n--------------------------------RESULTADO--------------------------------")
   print(result)
   print("--------------------------------RESULTADO--------------------------------\n\n\n")
   stopPresentation()
end  

   
local msgTable = {
  address = "http://9kgames.com/WS/WSIP2Country.asmx",
  namespace = "http://tempuri.org/",
  operationName = "GetCountryCode",
  params = {
    ipAddress = "64.233.163.104" --IP do Google
  }  
}

ncluasoap.call(msgTable, getResponse)

