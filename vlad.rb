require 'mail'
require 'pp'
require 'pstore'
require 'dedent'
require 'trollop'

class Array
    def only
        throw "Only failed: Oh god there are too many" if self.length > 1
        throw "Only failed: There's no one left" if self.length < 1
        self[0]
    end
end

class User
    def initialize(emails, display_name=nil)

        if emails.is_a? String
            emails = [ emails ]
        end
        @canonical_email = emails[0]
        display_name = @canonical_email if display_name.nil?
        @display_name = display_name
        @emails = emails
    end

    def format_date report_period
        report_period.iso8601
    end

    attr_accessor :canonical_email, :display_name, :emails
end

class Report
    def initialize(message)
        @message = message
    end
    def from
        @message.from[0]
    end
    def body
        unless @message.body.multipart?
            @message.body.decoded
        else
            @message.body.parts.each do |part|
                if part.content_type.include? "text/plain"
                    return part.body.decoded
                elsif part.content_type.include? "text/html"
                    return "<HTML EMAIL NOT YET SUPPORTED>" #part.body.decoded
                end
            end
        end
    end
    def snippet_content
        quotes_removed = body.gsub(/^\w*On.*wrote:\s*$|^\s*>.*$/, '')
        quotes_removed.strip + "\n"
    end
    def to_s
        out = {
            from: from
        }
        out.to_s
    end
end

class Vlad
    def initialize
        me = self
        smtp_options = {:address              => "smtp.gmail.com",
                        :port                 => 587,
                        :domain               => 'gmail.com',
                        :user_name            => me.username,
                        :password             => me.password,
                        :authentication       => 'plain',
                        :enable_starttls_auto => true  
        }

        Mail.defaults do
            retriever_method :pop3, :address    => "pop.gmail.com",
                                    :port       => 995,
                                    :user_name  => me.username,
                                    :password   => me.password,
                                    :enable_ssl => true
            delivery_method :smtp, smtp_options
        end

        @users = [ User.new("vanceza@gmail.com") ]
    end

    def today
        DateTime.now.to_date # report period
    end

    def yesterday
        DateTime.now.to_date.prev_day
    end

    def send_all! emails
        emails.each { |email| email.deliver! }
    end

    def report_requests
        users.map do |user|
            report_request = Mail.new
            report_request[:subject] = "What did you do today? #{user.format_date today}"
            report_request[:from] = email
            report_request[:to] = user.canonical_email
            #yesterdays_reports = "<NOT DONE>"

            report_request[:body] = <<-EMAIL.dedent
                Hey #{user.display_name},


                What did you do today (#{user.format_date today})?

                Work, chores, coding, conversations, anything... or nothing.  Just reply to this email and VladTheRemailer will will send out a compilation tomorrow morning.

                - Vlad The Remailer
                EMAIL
            report_request
        end        
    end

    def find_user_by_email email
        matches = @users.find do |user|
            user.emails.include? email
        end
    end

    def summary_section_for(user, report=nil)
        out = "#{user.display_name} report on #{user.format_date yesterday}:\n\n"
        out + if report.nil?
            "- No snippets submitted\n"
        else 
            report.snippet_content
        end
    end
    def summarize reports
        sections = @users.shuffle.map do |user|
            report = reports.find do |report|
                report_user = find_user_by_email report.from
                user == report_user
            end
            summary_section_for user, report
        end
        sections.compact.join("\n\n")
    end
    def remail_summaries
        me = self
        common_body = summarize latest_unprocessed_reports
        users.map do |user|
            summary = Mail.new
            summary.from = email
            summary.to = user.canonical_email
            summary.subject = "VladTheRemailer Summary"
            summary.body = common_body
            summary
        end
    end

    def unprocessed_emails
        emails = Mail.all
        today = report_period DateTime.new
        write do |db|
            db[:unprocessed_emails] ||= []
            db[:unprocessed_emails] += emails
        end
    end

    def mark_emails_processed!
        write do |db|
            processing = db[:unprocessed_emails]
            db[:unprocessed_emails] = []
            db[:processed_emails] ||= []
            db[:processed_emails] += [processing]
        end
    end

    def unprocessed_reports
        all_reports = unprocessed_emails.map { |email| Report.new email }
        all_reports.reject { |report| find_user_by_email(report.from).nil? }
    end

    def latest_unprocessed_reports
        by_user = unprocessed_reports.group_by { |report| report.from }
        by_user.map { |user, reports| reports.last }
    end

    def report_period dt
        dt.to_date
    end

    def email
        "Vlad the Remailer <vlad.the.remailer@gmail.com>"
    end
    def username
        "vlad.the.remailer@gmail.com"
    end
    def password
        "remailerpassword"
    end

    def database
        "emails.pstore"
    end
    def write &block
        PStore.new(database).transaction &block
    end

    def daily_summary!
        send_all! remail_summaries
        mark_emails_processed!
    end

    def daily_report_request!
        send_all! report_requests
    end

    attr_accessor :users
end

vlad = Vlad.new
opts = Trollop::options do
    opt :solicit, "Send out the daily reminders to submit reports"
    opt :summary, "Send out the daily summary of yesterday's reports"
end

if opts.solicit
    PP.pp vlad.daily_report_request!
elsif opts.summary
    PP.pp vlad.daily_summary!
else
    PP.pp vlad.latest_unprocessed_reports
end