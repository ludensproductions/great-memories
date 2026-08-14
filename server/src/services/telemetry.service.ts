import { snakeCase } from 'lodash';
import { OnEvent } from 'src/decorators';
import { GreatMemoriesWorker, JobStatus } from 'src/enum';
import { ArgOf, ArgsOf } from 'src/repositories/event.repository';
import { BaseService } from 'src/services/base.service';

export class TelemetryService extends BaseService {
  @OnEvent({ name: 'AppBootstrap', workers: [GreatMemoriesWorker.Api] })
  async onBootstrap(): Promise<void> {
    const userCount = await this.userRepository.getCount();
    this.telemetryRepository.api.addToGauge('great-memories.users.total', userCount);
  }

  @OnEvent({ name: 'UserCreate' })
  onUserCreate() {
    this.telemetryRepository.api.addToGauge(`great-memories.users.total`, 1);
  }

  @OnEvent({ name: 'UserTrash' })
  onUserTrash() {
    this.telemetryRepository.api.addToGauge(`great-memories.users.total`, -1);
  }

  @OnEvent({ name: 'UserRestore' })
  onUserRestore() {
    this.telemetryRepository.api.addToGauge(`great-memories.users.total`, 1);
  }

  @OnEvent({ name: 'JobStart' })
  onJobStart(...[queueName]: ArgsOf<'JobStart'>) {
    const queueMetric = `great-memories.queues.${snakeCase(queueName)}.active`;
    this.telemetryRepository.jobs.addToGauge(queueMetric, 1);
  }

  @OnEvent({ name: 'JobSuccess' })
  onJobSuccess({ job, response }: ArgOf<'JobSuccess'>) {
    if (!(response && Object.values(JobStatus).includes(response as JobStatus))) {
      return;
    }

    const jobMetric = `great-memories.jobs.${snakeCase(job.name)}.${response}`;
    this.telemetryRepository.jobs.addToCounter(jobMetric, 1);
  }

  @OnEvent({ name: 'JobError' })
  onJobError({ job }: ArgOf<'JobError'>) {
    const jobMetric = `great-memories.jobs.${snakeCase(job.name)}.${JobStatus.Failed}`;
    this.telemetryRepository.jobs.addToCounter(jobMetric, 1);
  }

  @OnEvent({ name: 'JobComplete' })
  onJobComplete(...[queueName]: ArgsOf<'JobComplete'>) {
    const queueMetric = `great-memories.queues.${snakeCase(queueName)}.active`;
    this.telemetryRepository.jobs.addToGauge(queueMetric, -1);
  }

  @OnEvent({ name: 'QueueStart' })
  onQueueStart({ name }: ArgOf<'QueueStart'>) {
    this.telemetryRepository.jobs.addToCounter(`great-memories.queues.${snakeCase(name)}.started`, 1);
  }
}
