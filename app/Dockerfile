FROM node:20-slim

WORKDIR /usr/src/app

COPY package*.json ./

# 如果沒有 package.json，則手動安裝 express 與 pg
RUN if [ -f package.json ]; then npm install; else npm install express pg; fi

COPY . .

EXPOSE 3000

CMD ["node", "index.js"]
