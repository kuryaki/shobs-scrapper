const axios = require('axios');
const cheerio = require('cheerio');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const getPosts = async () => {
	try {
		const { data } = await axios.get('https://www.indeed.com/jobs?q=Engineering%20Manager&l=Remote');
		const $ = cheerio.load(data);
		const posts = [];

		$('.resultContent').each((_idx, el) => {
            const title = $(el).find('.jobTitle');
            const company = $(el).find('.companyInfo');
            const salary = $(el).find('.salaryOnly');
            const post = {
                source: 'indeed',
                externalId: title.find('a').attr('id'),
                isNew: title.children().length === 2,
                title: title.children().last().text(),
                company: company.find('.companyName').text(),
                location: company.find('.companyLocation').text(),
                salary: salary.children().first().text(),
                duration: salary.children().last().text(),
            };
			posts.push(post)
		});

		return posts;
	} catch (error) {
		throw error;
	}
};

const savePosts = async (posts) => {
    try {
        await prisma.posts.createMany({
            data: posts,
            skipDuplicates: true
        })
    } catch (error) {
		throw error;
	}
}

getPosts()
    .then(savePosts)
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect()
    });
