const axios = require('axios');
const cheerio = require('cheerio');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();


const getPage = async (search, location , start) => {
    try {
        let posts = [];
        let lastPage = false;
        const perPage = 10;

        while(!lastPage) {
            const url = `https://www.indeed.com/jobs?q=${search}&l=${location}&start=${start}`;
            const { data } = await axios.get(url);
            const $ = cheerio.load(data);
            lastPage = !!$('.pagination-list li').last().text();
            start += perPage;
            const batch = await getPosts($);
            posts = posts.concat(batch);
            console.log(url, batch.length, posts.length, { lastPage });
        }

        return posts;
    } catch (error) {
        throw error;
    }
}

const getPosts = async ($) => {
	try {
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
    console.log(posts.length, 'processed');
    try {
        await prisma.posts.createMany({
            data: posts,
            skipDuplicates: true
        })
    } catch (error) {
		throw error;
	}
}

getPage('Software%20Engineer', 'Remote', 0)
 .then(savePosts)
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect()
    });
