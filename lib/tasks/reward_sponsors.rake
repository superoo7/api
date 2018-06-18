require 'radiator'
require 's_logger'
require 'utils'

desc 'Reward Sponsors'
task :reward_sponsors, [:week, :steem_to_distribute, :write]=> :environment do |t, args|
  week = args[:week].to_i
  steem_to_distribute = args[:steem_to_distribute].to_f
  should_write = args[:write].to_i == 1

  WEEKLY_HUNT_DISTRIBUTION = 630000
  REWARD_OPT_OUT = ['tabris', 'project7', 'misterdelegation']

  logger = SLogger.new('reward-log')
  logger.log "== SPONSOR REWARD DISTRIBUTION - WEEK #{week} ==", true

  begin
    # REF: https://helloacm.com/tools/steemit/delegators/
    uri = URI('https://uploadbeta.com/api/steemit/delegators/?id=steemhunt&hash=64266499d925926f0fd9d500c4f109eb')
    response = Net::HTTP.get(uri)
    json = JSON.parse(response)
  rescue => e
    logger.log "ERROR: API Failed - #{e.message}"
  end

  total_vests = 0.0
  total_opt_out_vests = 0.0
  total_sps = 0.0
  json.each do |j|
    total_vests += j['vests']
    total_sps += j['sp']

    if REWARD_OPT_OUT.include?(j['delegator'])
      total_opt_out_vests += j['vests']
    end
  end

  logger.log "\n==========\nTotal: #{formatted_number(total_vests)} VESTS (#{formatted_number(total_sps.round)} SP) / #{formatted_number(total_opt_out_vests)} VESTS OPETED OUT\n==========", true

  logger.log "|  User Name  |   Delegated   | STEEM Rewards | HUNT Tokens Reserved | HUNT Tokens Total |"
  logger.log "|-------------|---------------|---------------|----------------------|-------------------|"

  total_steem_distributed = 0.0
  total_hunt_distributed = 0.0
  total_proportion = 0.0
  total_hunt_accumulated = 0.0
  steem_transactions = []
  ActiveRecord::Base.transaction do # transaction
    json.each do |j|
      hunt_balance = 0

      if REWARD_OPT_OUT.include?(j['delegator'])
        proportion = steem = hunt = 0
      else
        proportion = j['vests'] / (total_vests - total_opt_out_vests)
        steem = steem_to_distribute * proportion
        hunt  = WEEKLY_HUNT_DISTRIBUTION * proportion
        total_proportion += proportion
        total_steem_distributed += steem
        total_hunt_distributed += hunt

        if should_write
          HuntTransaction.reward_sponsor! j['delegator'], hunt, week

          if steem > 0.001
            steem_transactions << {
              type: :transfer,
              from: 'steemhunt.pay',
              to: j['delegator'],
              amount: "#{steem.round(3)} STEEM",
              memo: 'Steemhunt weekly reward from the sponsor program'
            }
          end
        end

        hunt_balance = User.find_by(username: j['delegator']).try(:hunt_balance).to_f
        total_hunt_accumulated += hunt_balance
      end

      logger.log "| @#{j['delegator']} | #{formatted_number(j['vests'], 0)} VESTS (#{formatted_number(j['sp'].round, 0)} SP) | " +
        "#{formatted_number(steem, 3)} | #{formatted_number(hunt, 0)} | #{formatted_number(hunt +hunt_balance, 0)} |"
    end
  end

  logger.log "| Total | #{formatted_number(total_vests)} VESTS (#{formatted_number(total_sps.round)} SP) | " +
        "#{(total_proportion * 100).round(2)}% | #{formatted_number(total_steem_distributed, 3)} | " +
        "#{formatted_number(total_hunt_distributed, 0)} | #{formatted_number(total_hunt_distributed + total_hunt_accumulated, 0)} |"

  logger.log "\n==========\nSEND #{formatted_number(total_steem_distributed)} STEEM TO #{steem_transactions.size} SPONSORS (#{json.size - steem_transactions.size} omitted less than 0.001)\n==========", true

  if should_write
    steem_transactions.each do |t|
      tx = Radiator::Transaction.new(wif: ENV['STEEMHUNT_PAY_ACTIVE_KEY'])
      tx.operations << t
      result = tx.process(true)
      logger.log "Sent to @#{t[:to]} - #{t[:amount]} STEEM", true
    end
  end

  logger.log "== FINISHED SPONSOR REWARD DISTRIBUTION - WEEK #{week}: " +
    "#{formatted_number(total_sps.round)} SP (by #{steem_transactions.size} sponsors) / " +
    "#{formatted_number(total_steem_distributed)} STEEMs distributed ==", true
end

