---Aplicação de exemplo que consome um Web Service para obtenção
--da letra de uma música.
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

---Função usada para tratar a resposta da requisição da letra
--de uma determinada música ao WebService Lyrics
--@param result Resultado da chamada ao método remoto via SOAP.
--No caso deste Web Service, o resultado é uma tabela com vários campos.
local function getResponse(result)
   --Forma de uso com NCLua SOAP anterior a 0.5.6
   --return é o nome da chave na qual o valor retornado pelo WS é armazenado, como apresentado no XML de retorno
   -- for k, v in pairs(result["return"]) do print(k, v)  end

   print("\n\n\n--------------------------------RESULTADO--------------------------------")
   for k, v in pairs(result) do
      print(k..":", v, "\n")
   end
   print("--------------------------------RESULTADO--------------------------------\n\n\n")

   --Alternativa para imprimir todos os dados da tabela (requer o uso do módulo util):
   --util.printable(result)

   stopPresentation()
end  
   

local msgTable = {
  --address = "http://lyricwiki.org/server.php",
  address = "http://lyrics.wikia.com/server.php",
  namespace = "LyricWiki",
  operationName = "getSong",
  params = {
    artist = "Nando Reis",
    song = "Dessa Vez"
  }  
}

ncluasoap.call(msgTable, getResponse)

