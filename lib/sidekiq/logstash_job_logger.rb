# frozen_string_literal: true

require 'sidekiq/logging/shared'

module Sidekiq
  # Class used to replace Sidekiq 5 job logger.
  class LogstashJobLogger
    include Sidekiq::Logging::Shared

    def call(job, _queue, &block)
      log_job(job, &block)
    end

    def prepare(job_hash, &block)
      level = job_hash["log_level"]
      if level
        Sidekiq.logger.log_at(level) do
          Sidekiq::Context.with(job_hash_context(job_hash), &block)
        end
      else
        Sidekiq::Context.with(job_hash_context(job_hash), &block)
      end
    end

    private
    def job_hash_context(job_hash)
      # If we're using a wrapper class, like ActiveJob, use the "wrapped"
      # attribute to expose the underlying thing.
      h = {
        class: job_hash["wrapped"] || job_hash["class"],
        jid: job_hash["jid"]
      }
      h[:bid] = job_hash["bid"] if job_hash["bid"]
      h[:tags] = job_hash["tags"] if job_hash["tags"]
      h
    end
  end
end
