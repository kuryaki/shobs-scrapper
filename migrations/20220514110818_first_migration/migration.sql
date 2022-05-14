/*
  Warnings:

  - You are about to drop the `Post` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropTable
DROP TABLE "Post";

-- CreateTable
CREATE TABLE "posts" (
    "id" SERIAL NOT NULL,
    "source" TEXT NOT NULL,
    "externalId" TEXT NOT NULL,
    "isNew" BOOLEAN NOT NULL DEFAULT false,
    "title" TEXT NOT NULL,
    "company" TEXT NOT NULL,
    "location" TEXT NOT NULL,
    "salary" TEXT NOT NULL,
    "duration" TEXT NOT NULL,

    CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "posts_externalId_key" ON "posts"("externalId");
