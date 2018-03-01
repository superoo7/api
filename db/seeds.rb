# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Post.create!(
  author: 'heap',
  url: 'https://www.tradingview.com',
  title: 'Trading View',
  tagline: 'The best charting tool for crypto and stocks',
  tags: ['cryptocurrency', 'crypto'],
  images: [
    {'id'=>'6ukxaHi', 'name'=>'Screen Shot 2018-01-03 at 16.55.10.png', 'link'=>'https://i.imgur.com/6ukxaHi.png', 'width'=>955, 'height'=>695, 'type'=>'image/png', 'deletehash'=>'nUwpVyTNEcLOLlx'},
    {'id'=>'eGnlRVX', 'name'=>'Screen Shot 2018-01-03 at 16.54.27.png', 'link'=>'https://i.imgur.com/eGnlRVX.png', 'width'=>977, 'height'=>557, 'type'=>'image/png', 'deletehash'=>'oupOftrTmhE8PQE'},
    {'id'=>'S4EEEX9', 'name'=>'Screen Shot 2018-01-03 at 16.54.46.png', 'link'=>'https://i.imgur.com/S4EEEX9.png', 'width'=>827, 'height'=>696, 'type'=>'image/png', 'deletehash'=>'wMD92RvEOMO3LJw'},
    {'id'=>'M6o47o1', 'name'=>'Screen Shot 2018-01-03 at 16.54.37.png', 'link'=>'https://i.imgur.com/M6o47o1.png', 'width'=>819, 'height'=>695, 'type'=>'image/png', 'deletehash'=>'OmIg1z7OuP5Ffnr'}
  ],
  beneficiaries: nil,
  permlink: 'tradingview-the-best-charting-tool-for-crypto-and-stocks',

  payout_value: 3.09,
  active_votes: [{
    time: '2018-01-11T05:01:36',
    reputation: '6876627647139',
    percent: 10000,
    rshares: '19591401838',
    weight: 37368,
    voter: 'shellany'
  }, {
    time: '2018-01-11T03:54:03',
    reputation: '5915891656959',
    percent: 300,
    rshares: 590064802,
    weight: 1125,
    voter: 'st3llar'
  }],
  children: 0,
)