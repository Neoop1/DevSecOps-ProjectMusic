FROM node:16.17.0-alpine
WORKDIR /app
COPY ./package.json .
COPY ./yarn.lock .
RUN yarn install
COPY . .
RUN yarn build
EXPOSE 3000
CMD ["yarn", "start", "--host", "0.0.0.0"]
